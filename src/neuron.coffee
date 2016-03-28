window.Node = class Node
  # Static ID counter
  @currentID:0
  constructor: (@x, @y)->
    @id = Node.currentID++
    @bias=0
    @inputWeights=[]
    @inputs=[]
    @outputs=[]
    @outputValue=0
  # Get the D3 selection associated with the node
  getAssociatedElement: () ->
    return d3.select("#node_" + @id)

window.Edge =class Edge
  constructor: (@start_id, @finish_id) ->

window.Network = class Network
  constructor: () ->
    @nodes = []
    @edges = []
    @inputNodes = []
    @outputNodes = []
    @selectedNode = null

  # Get a node from myNodes based off of ID, null if not found
  indexNodesById: (id) ->
    for i in [0..@nodes.length - 1]
      return @nodes[i] if @nodes[i].id == id
    return null 

  # Set or unset the nodes on an edge as an input or output node if applicable
  setIONodeStatus: (edge) ->
    nodeStart = @indexNodesById(edge.start_id)
    nodeFinish = @indexNodesById(edge.finish_id)
    # Set I/O nodes
    @setInputNodeStatus(nodeStart)
    @setOutputNodeStatus(nodeFinish)
    # Unset I/O nodes if applicable
    @deleteNodeFromList(@inputNodes, nodeFinish)
    @deleteNodeFromList(@outputNodes, nodeStart)

  # Set a node as an input node if applicable
  setInputNodeStatus: (node) ->
    if node.inputs.length == 0 && @inputNodes.indexOf(node) == -1
      @inputNodes.push(node)

  # Set a node as an output node if applicable
  setOutputNodeStatus:  (node) ->
    if node.outputs.length == 0 && @outputNodes.indexOf(node) == -1
      @outputNodes.push(node)

  # Returns true if deleted, false if node is not in list
  deleteNodeFromList: (list, node) ->
    index = list.indexOf(node)
    if index != -1
      list.splice(index, 1)
      return true
    else
      return false

  deleteNode:(node) ->
    # Remove all associated edges via filter
    @edges = @edges.filter((edge) =>
      if node.outputs.indexOf(edge) != -1
        # Check if the end of the edge is a valid input node after deletion
        finishNode = @indexNodesById(edge.finish_id);
        finishNode.inputs.splice(finishNode.inputs.indexOf(edge))
        @setInputNodeStatus(finishNode)
        return false
      else if node.inputs.indexOf(edge) != -1
        # Remove edge reference from the start of the edge and
        # Check if the start of the edge is a valid output node after deletion
        startNode = @indexNodesById(edge.start_id);
        startNode.outputs.splice(startNode.outputs.indexOf(edge))
        @setOutputNodeStatus(startNode)
        return false
      else
        return true
    )
    # Find the node in every list and delete it
    @deleteNodeFromList(@nodes, node)
    @deleteNodeFromList(@inputNodes, node)
    @deleteNodeFromList(@outputNodes, node)
    if selectedNode == node
      selectedNode = null

  # Create an edge between 2 nodes, returns true if okay, error otherwise
  createEdge: (start, finish) ->
    edge = new Edge(start.id, finish.id)
    # Remove any edges that are the opposite of the new one
    filteredEdges = @edges.filter((elem) ->
      if elem.start_id == edge.finish_id && elem.finish_id == edge.start_id
        @edges.splice(@edges.indexOf(elem), 1)
      return elem.start_id == edge.start_id && elem.finish_id == edge.finish_id
    )
    if filteredEdges .length == 0
      # Make sure that the graph doesn't contain cycles
      start.outputs.push(edge)
      finish.inputs.push(edge)
      finish.inputWeights.push(1)
      @edges.push(edge)
      if @isCyclic()
        start.outputs.pop()
        finish.inputs.pop()
        finish.inputWeights.pop()
        @edges.pop()
        return "Graph cannot be cyclic!"
      else
        @setIONodeStatus(edge)
        return true

  isCyclic:() ->
    # Init visited and recursive stack arrays
    visited = []
    recStack = []
    for i in [0..@nodes.length - 1]
      do (i) ->
        visited[i] = false
        recStack[i] = false

    # Recursive helper function
    helper= (i) =>
      if visited[i] == false
        visited[i] = true
        recStack[i] = true
        for edge in @nodes[i].outputs
          j = @nodes.indexOf(@indexNodesById(edge.finish_id))
          if !visited[j] && helper(j)
            return true
          else if recStack[j]
            return true
      recStack[i] = false
      return false

    for i in [0..@nodes.length - 1]
      return true if helper(i)
    return false


  # Compute the result of the network
  computeResult: () ->
    # Compute the sigmoid of a node
    computeSigmoid= (inputs, node) ->
      # First check that the inputs are valid
      if inputs.length != node.inputWeights.length
        console.error("Input and Input Weight length mismatch on node_", node.id)
        return
      sigma = 0
      for i in [0..inputs.length - 1]
        sigma += inputs[i]*node.inputWeights[i]
      return 1/(1 + Math.pow(Math.E ,sigma - node.bias))

    # returns the output of a given node
    resolveNode = (node) ->
      # Check to see if the node is an input node
      if node.inputs.length == 0
        return node.bias
      # Resolve all of the inputs
      inputs = []
      for edge in node.inputs
        do(edge) ->
          inputs.push(resolveNode(indexNodesById(edge.start_id)))
      return computeSigmoid(inputs, node)

    # Start at the end and work our way backwards
    for outputNode in @outputNodes
      outputNode.outputValue = resolveNode(outputNode)

D3Closure = () ->
  network = null;
  selectedNodeData = {}
  mouseDownNode= null
  shiftDrag= false


  # Hold SVG Groups for edges and nodes
  nodesG = null
  edgesG = null

  # Container Elements
  neuronContainer = null;
  neuronSvg = null;
  
  neuronPanelWeights = null;
  neuronPanelBias = null;
  neuronPanelBiasInput = null;


  # Shift + Drag line
  shiftDragLine = null


  # Drag behaviour
  nodeDrag = d3.behavior.drag()
    .origin (d) ->
      return d
    .on "drag", (d) ->
      if shiftDrag
        shiftDragLine.attr("d", generatePath(d.x, d.y, d3.mouse(neuronSvg.node())[0], d3.mouse(neuronSvg.node())[1]))
      else
        d.x = d3.event.x
        d.y = d3.event.y
        # Move both the circle and the text
        d3.select(this).select("circle").attr("cx", d.x).attr("cy", d.y)
        d3.select(this).select("text").attr("x", d.x).attr("y", d.y)
        update()

  d3Closure = (container) ->
    network = new Network()
    neuronContainer = d3.select(container)
    neuronPanelBias = d3.select("#neuron-panel-bias")
    neuronPanelWeights = d3.select("#neuron-panel-weights")
    d3.select("#compute-button").on("click", network.computeResult)
    neuronSvg = neuronContainer.append("svg")
    .attr("class", "neuron-svg")
    svgDefs = neuronSvg.append("svg:defs")
    # This makes a triangle, don't question it
    # We hide the viewbox off screen in order to load the SVG without showing it
    svgDefs.append("svg:marker")
      .attr("id", "drag-arrow")
      .attr("viewBox", "-5 -5 10 10")
      .attr("refX", "0")
      .attr("refY", "0")
      .attr("markerWidth", "5")
      .attr("markerHeight", "5")
      .attr("markerUnits", "strokeWidth")
      .attr("orient", "auto")
      .append("svg:path")
      .attr("d", "M0 0 m -5 -5 L 5 0 L -5 5 Z")
    svgDefs.append("svg:marker")
      .attr("id", "edge-arrow")
      .attr("viewBox", "-5 -5 10 10")
      .attr("refX", "17")
      .attr("refY", "0")
      .attr("markerWidth", "5")
      .attr("markerHeight", "5")
      .attr("markerUnits", "strokeWidth")
      .attr("orient", "auto")
      .append("svg:path")
      .attr("d", "M0 0 m -5 -5 L 5 0 L -5 5 Z")
    shiftDragLine = neuronSvg.append("svg:path")
      .style("marker-end", "url(#drag-arrow)")
      .attr("class", "link")
      .attr("d", generatePath(0,0,0,0))
    shiftDragLine.classed("hidden", true)
    edgesG = neuronSvg.append("g").attr("id", "edges")
    nodesG = neuronSvg.append("g").attr("id", "nodes")
    neuronSvg.on('dblclick', svgDoubleClick)
    neuronSvg.on("mousedown", svgMouseDown)
    neuronSvg.on("mouseup", svgMouseUp)
    # Setup Bias
    neuronPanelBiasInput = neuronPanelBias.append("input")
      .attr("type", "hidden")
      .attr("id", "input_bias")
      .attr("value", "1")
      .on("input", () ->
        selectedNode.bias = this.value
        update()
      )
    update()




  # Create a path for an SVG Line
  generatePath = (x0, y0, x1, y1) ->
    # The d attribute specifies a path for an SVG Line
    # M Specifies an origin for the line
    # L actually draws the line
    "M " + x0 + " " + y0 + " L " + x1 + " " + y1



  # Svg Mouse Handlers
  svgDoubleClick = () ->
    return if d3.event.defaultPrevented
    coords = d3.mouse(neuronSvg.node())
    node = new Node(coords[0], coords[1])
    network.nodes.push(node)
    update()

  svgMouseDown = () ->
    clearPanel()

  svgMouseUp = () ->
    if shiftDrag
      shiftDragLine.classed("hidden", true)
      shiftDrag = false

  # Node Mouse Handlers
  nodeMouseDown = (d) ->
    # Because this is where we handle all mouse events on nodes,
    # We stop the propagation of the even
    d3.event.stopPropagation()
    # Store the current node so we know if there is a link or not
    mouseDownNode = d
    if d3.event.shiftKey
      shiftDrag = true
      shiftDragLine.classed('hidden', false)
        .attr("d", generatePath(d.x, d.y, d.x, d.y))

  nodeMouseUp = (d) ->
    shiftDrag = false
    return if !mouseDownNode
    if mouseDownNode != d
        result = network.createEdge(mouseDownNode, d)
        if !result
          alert(result)
        update()
    else
      # We have just clicked on a node
      network.selectedNode = mouseDownNode
      showPanel()
      # Load all data to the side panel
    shiftDragLine.classed("hidden", true)


  nodeRightClick = (d) ->
    d3.event.preventDefault()
    deleteNode(d)
    update()

  updateNodes = () ->
    nodeSelection = nodesG.selectAll("g").data(network.nodes, (d) -> d.id)
    enterNodeSelection = nodeSelection.enter().append("g")
      .on("contextmenu", nodeRightClick)
      .on("mousedown", nodeMouseDown)
      .on("mouseup", nodeMouseUp)
      .call(nodeDrag)
    enterNodeSelection.append("circle")
    enterNodeSelection.append("text")
    # Update the selection
    nodeSelection.select("text")
      .text((d) ->
        "ID: " + d.id
      )
      .attr("x", (d) -> d.x + "px")
      .attr("y", (d) -> d.y + "px")
      .attr("text-anchor", "middle")
      .attr("fill", "#333")
    nodeSelection.select("circle")
      .attr("cx", (d) -> d.x + "px")
      .attr("cy", (d) -> d.y + "px")
      .attr("r", "40")
      .attr("class", "node")
    nodeSelection
      .attr("id", (d) -> "node_" + d.id)
      .classed("node-input", (d) -> network.inputNodes.indexOf(d) != -1)
      .classed("node-output", (d) ->  network.outputNodes.indexOf(d) != -1)
    nodeSelection.exit().remove()

  updateEdges = () ->
    edgeSelection = edgesG.selectAll("g").data(network.edges, (d) -> d.start_id + "+" + d.finish_id)
    enterEdgeSelection = edgeSelection.enter().append("g")
    enterEdgeSelection.append("path")
      .style("marker-end", "url(#edge-arrow)")
      .classed("link", true)
    enterEdgeSelection.append("text").append("textPath")
    .attr("xlink:href", (d,i) -> "#linkId_" + i)
    edgeSelection.select("path")
      .attr("id", (d,i) -> "linkId_" + i)
      .attr("d", (edge) ->
        startNode = network.indexNodesById(edge.start_id)
        finishNode = network.indexNodesById(edge.finish_id)
        generatePath(startNode.x, startNode.y, finishNode.x, finishNode.y)
      )
    edgeSelection.select("text")
      .attr("text-anchor", "end")
      .attr("dx", (edge) ->
        # Get the length of the path
        startNode = network.indexNodesById(edge.start_id)
        finishNode = network.indexNodesById(edge.finish_id)
        distance = Math.sqrt(Math.pow(startNode.x - finishNode.x, 2) + Math.pow(startNode.y - finishNode.y, 2))
        return distance - 100
      )
      .attr("dy", "-10")
      .attr("fill", "#333")
    edgeSelection.select("textPath")
    .text((edge) ->
      finishNode = network.indexNodesById(edge.finish_id)
      "" + finishNode.inputs.indexOf(edge)
    )
    edgeSelection
    .attr("id", (d) -> "edge_" + d.start_id + "-" + d.finish_id)
    edgeSelection.exit().remove()

  clearPanel = () ->
    neuronPanelBiasInput.attr("type", "hidden")
    selectedNodeData.inputWeights = []
    selectedNodeData.bias = 0
    updatePanel()

  showPanel = () ->
    selectedNodeData.inputWeights = selectedNode.inputWeights
    selectedNodeData.bias = selectedNode.bias
    neuronPanelBiasInput.attr("type", "text")
    neuronPanelBiasInput.property("value", selectedNodeData.bias)
    # Check to see if we should enable the checkboxes
    updatePanel()

  updatePanel = () ->
    # Setup Weights
    weightSelection = neuronPanelWeights.selectAll("div").data(selectedNodeData.inputWeights)
    weightContainer =weightSelection.enter().append("div")
    .classed("weight-container", true)
    weightContainer.append("label")
    .attr("for", (d,i) -> "input_weight_" + i)
    .text((d,i) -> i + ":")
    weightContainer.append("input")
    .attr("type", "input")
    .attr("value", (d) -> d)
    .attr("id", (d,i) -> "input_weight_" + i)
    .on("input", (d,i) ->
      selectedNode.inputWeights[i] = this.value
      update()
    )
    weightSelection.exit().remove()

  # Re-render the graph
  update = () ->
    updateNodes()
    updateEdges()
    shiftDragLine.classed("hidden", true)
    
  return d3Closure

$ ->
  myD3Closure = D3Closure
  myD3Closure('#neuron')
