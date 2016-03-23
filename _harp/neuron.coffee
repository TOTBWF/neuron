class Node
  # Static ID counter
  @currentID:0
  constructor: (@x, @y)->
    @id = Node.currentID++
    @bias=0
    @inputWeights=[]
    @inputs=[]
    @outputs=[]

  # Get the D3 selection associated with the node
  getAssociatedElement: () ->
    return d3.select("#node_" + @id)

class Edge
  constructor: (@start_id, @finish_id) ->

Network = () ->
  # Store list of node and edge data
  myNodes = []
  myEdges = []

  nodeInputs = []
  nodeOutputs = []

  selectedNodeData = {}

  state = {
    mouseDownNode: null,
    shiftDrag: false,
  }
  selectedNode = null


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
      if state.shiftDrag
        shiftDragLine.attr("d", generatePath(d.x, d.y, d3.mouse(neuronSvg.node())[0], d3.mouse(neuronSvg.node())[1]))
      else
        d.x = d3.event.x
        d.y = d3.event.y
        # Move both the circle and the text
        d3.select(this).select("circle").attr("cx", d.x).attr("cy", d.y)
        d3.select(this).select("text").attr("x", d.x).attr("y", d.y)
        update()

  network = (container, nodes, edges) ->
    neuronContainer = d3.select(container)
    neuronPanelBias = d3.select("#neuron-panel-bias")
    neuronPanelWeights = d3.select("#neuron-panel-weights")
    d3.select("#compute-button").on("click", computeResult)
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


  # Utility Functions
  setIONodeStatus = (edge) ->
    nodeStart = indexNodesById(edge.start_id)
    nodeFinish = indexNodesById(edge.finish_id)
    # Set I/O nodes
    setInputNodeStatus(nodeStart)
    setOutputNodeStatus(nodeFinish)
    # Unset I/O nodes if applicable
    deleteNodeIfExists(nodeInputs, nodeFinish)
    deleteNodeIfExists(nodeOutputs, nodeStart)
      
  setInputNodeStatus = (node) ->
    if node.inputs.length == 0 && nodeInputs.indexOf(node) == -1
      nodeInputs.push(node)
  
  setOutputNodeStatus = (node) ->
    if node.outputs.length == 0 && nodeOutputs.indexOf(node) == -1
      nodeOutputs.push(node)
    
  # Create a path for an SVG Line
  generatePath = (x0, y0, x1, y1) ->
    # The d attribute specifies a path for an SVG Line
    # M Specifies an origin for the line
    # L actually draws the line
    "M " + x0 + " " + y0 + " L " + x1 + " " + y1

  # Get a node from myNodes based off of ID
  indexNodesById = (id) ->
    for i in [0..myNodes.length - 1]
      return myNodes[i] if myNodes[i].id == id
    return -1

  # Returns true if deleted, false if node is not in list
  deleteNodeIfExists = (list, node) ->
    index = list.indexOf(node)
    if index != -1
      list.splice(index, 1)
      return true
    else
      return false

  # Svg Mouse Handlers
  svgDoubleClick = () ->
    return if d3.event.defaultPrevented
    coords = d3.mouse(neuronSvg.node())
    node = new Node(coords[0], coords[1])
    myNodes.push(node)
    update()

  svgMouseDown = () ->
    clearPanel()

  svgMouseUp = () ->
    if state.shiftDrag
      shiftDragLine.classed("hidden", true)
      state.shiftDrag = false

  # Node Mouse Handlers
  nodeMouseDown = (d) ->
    # Because this is where we handle all mouse events on nodes,
    # We stop the propagation of the even
    d3.event.stopPropagation()
    # Store the current node so we know if there is a link or not
    state.mouseDownNode = d
    if d3.event.shiftKey
      state.shiftDrag = true
      shiftDragLine.classed('hidden', false)
        .attr("d", generatePath(d.x, d.y, d.x, d.y))

  nodeMouseUp = (d) ->
    state.shiftDrag = false
    mouseDownNode = state.mouseDownNode
    return if !mouseDownNode
    if state.mouseDownNode != d
      # We have made a connection
      edge = new Edge(mouseDownNode.id, d.id)
      # Remove any edges that are the opposite of the new one
      filteredEdges = myEdges.filter((elem) ->
        if elem.start_id == edge.finish_id && elem.finish_id == edge.start_id
          myEdges.splice(myEdges.indexOf(elem), 1)
        return elem.start_id == edge.start_id && elem.finish_id == edge.finish_id
      )
      if filteredEdges .length == 0
        # Make sure that the graph doesn't contain cycles
        mouseDownNode.outputs.push(edge)
        d.inputs.push(edge)
        d.inputWeights.push(1)
        myEdges.push(edge)
        if isCyclic()
          mouseDownNode.outputs.pop()
          d.inputs.pop()
          d.inputWeights.pop()
          myEdges.pop()
          alert("Neural Networks Can't Be Cyclic!")
        else
          setIONodeStatus(edge)
        update()
    else
      # We have just clicked on a node
      selectedNode = mouseDownNode
      showPanel()
      # Load all data to the side panel

    shiftDragLine.classed("hidden", true)

  deleteNode = (node) ->
    console.log("Deleting node ", node.id)
    # Remove all associated edges via filter
    myEdges = myEdges.filter((edge) ->
      if node.outputs.indexOf(edge) != -1
        # Check if the end of the edge is a valid input node after deletion
        finishNode = indexNodesById(edge.finish_id);
        finishNode.inputs.splice(finishNode.inputs.indexOf(edge))
        setInputNodeStatus(finishNode)
        return false
      else if node.inputs.indexOf(edge) != -1
        # Remove edge reference from the start of the edge and
        # Check if the start of the edge is a valid output node after deletion
        startNode = indexNodesById(edge.start_id);
        startNode.outputs.splice(startNode.outputs.indexOf(edge))
        setOutputNodeStatus(startNode)
        return false
      else
        return true
    )
    # Find the node in every list and delete it
    deleteNodeIfExists(myNodes, node)
    deleteNodeIfExists(nodeInputs, node)
    deleteNodeIfExists(nodeOutputs, node)
    if selectedNode == node
      selectedNode = null

  nodeRightClick = (d) ->
    d3.event.preventDefault()
    deleteNode(d)
    update()

  updateNodes = () ->
    nodeSelection = nodesG.selectAll("g").data(myNodes, (d) -> d.id)
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
      .classed("node-input", (d) -> nodeInputs.indexOf(d) != -1)
      .classed("node-output", (d) ->  nodeOutputs.indexOf(d) != -1)
    nodeSelection.exit().remove()

  updateEdges = () ->
    edgeSelection = edgesG.selectAll("g").data(myEdges, (d) -> d.start_id + "+" + d.finish_id)
    enterEdgeSelection = edgeSelection.enter().append("g")
    enterEdgeSelection.append("path")
      .style("marker-end", "url(#edge-arrow)")
      .classed("link", true)
    enterEdgeSelection.append("text").append("textPath")
    .attr("xlink:href", (d,i) -> "#linkId_" + i)
    edgeSelection.select("path")
      .attr("id", (d,i) -> "linkId_" + i)
      .attr("d", (edge) ->
        startNode = indexNodesById(edge.start_id)
        finishNode = indexNodesById(edge.finish_id)
        generatePath(startNode.x, startNode.y, finishNode.x, finishNode.y)
      )
    edgeSelection.select("text")
      .attr("text-anchor", "end")
      .attr("dx", (edge) ->
        # Get the length of the path
        startNode = indexNodesById(edge.start_id)
        finishNode = indexNodesById(edge.finish_id)
        distance = Math.sqrt(Math.pow(startNode.x - finishNode.x, 2) + Math.pow(startNode.y - finishNode.y, 2))
        return distance - 100
      )
      .attr("dy", "-10")
      .attr("fill", "#333")
    edgeSelection.select("textPath")
    .text((edge) ->
      finishNode = indexNodesById(edge.finish_id)
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
    weightSelection = neuronPanelWeights.selectAll("input").data(selectedNodeData.inputWeights)
    weightSelection.enter().append("input")
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

  isCyclic = () ->
    # Init visited and recursive stack arrays
    visited = []
    recStack = []
    for i in [0..myNodes.length - 1]
      do (i) ->
        visited[i] = false
        recStack[i] = false

    # Recursive helper function
    helper = (i) ->
      if visited[i] == false
        visited[i] = true
        recStack[i] = true
        for edge in myNodes[i].outputs
          j = myNodes.indexOf(edge.finish)
          if !visited[j] && helper(j)
            return true
          else if recStack[j]
            return true
      recStack[i] = false
      return false

    for i in [0..myNodes.length - 1]
      return true if helper(i)
    return false
    
  computeSigmoid = (inputs, node) ->
    # First check that the inputs are valid
    if inputs.length != node.inputWeights.length
      console.error("Input and Input Weight length mismatch on node_", node.id)
      return
    sigma = 0
    for i in [0..inputs.length - 1]
      sigma += inputs[i]*node.inputWeights[i]
    return 1/(1 + Math.pow(Math.E ,sigma - node.bias))

  # Compute the result of the network
  computeResult = () ->
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
    outputString = ""
    for outputNode in nodeOutputs
      outputString += "node_" + outputNode.id + " = " + resolveNode(outputNode) + "\n"
    alert(outputString)
    update()

  return network

$ ->
  myNetwork = Network()
  myNetwork("#neuron", [], [])
