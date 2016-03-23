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
  constructor: (@start, @finish) ->

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
  
  neuronPanelInputRow = null;
  neuronPanelOutputRow = null;

  neuronPanelInputSwitch = null;
  neuronPanelOutputSwitch = null;


  # Shift + Drag line
  shiftDragLine = null

  # Create a path for an SVG Line
  generatePath = (x0, y0, x1, y1) ->
    # The d attribute specifies a path for an SVG Line
    # M Specifies an origin for the line
    # L actually draws the line
    "M " + x0 + " " + y0 + " L " + x1 + " " + y1

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
    neuronPanelInputRow = d3.select("#input-switch-row").style("display", "none")
    neuronPanelOutputRow = d3.select("#output-switch-row").style("display", "none")
    neuronPanelInputSwitch = d3.select("#input_toggle")
    neuronPanelOutputSwitch = d3.select("#output_toggle")
    neuronPanelInputSwitch.on("change", toggleInputNode)
    neuronPanelOutputSwitch.on("change", toggleOutputNode)
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
      edge = new Edge(mouseDownNode, d)
      # Remove any edges that are the opposite of the new one
      filteredEdges = myEdges.filter((elem) ->
        if elem.start == edge.finish && elem.finish == edge.start
          myEdges.splice(myEdges.indexOf(elem))
        return elem.start == edge.start && elem.finish == edge.finish
      )
      if filteredEdges .length == 0
        # First make sure we aren't linking to an input or from an output
        if nodeInputs.indexOf(edge.finish) != -1
          alert("You can't link to an input node")
          update()
          return
        else if nodeOutputs.indexOf(edge.start) != -1
          alert("You can't link from an output node")
          update()
          return
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
        update()
    else
      # We have just clicked on a node
      selectedNode = mouseDownNode
      showPanel()
      # Load all data to the side panel

    shiftDragLine.classed("hidden", true)

  deleteNode = (node) ->
    console.log("Deleting node ", node.id)
    # Find the node in every list and delete it
    index = myNodes.indexOf(node)
    console.log("Index of Node is ", index)
    if(index < 0)
      return
    # Remove all associated edges via filter
    myEdges = myEdges.filter((edge) ->
      if node.outputs.indexOf(edge) < 0 && node.inputs.indexOf(edge) < 0
        return true
    )
    myNodes.splice(index, 1)
    index = nodeInputs.indexOf(node)
    if(index < 0)
      nodeInputs.splice(index, 1)
    index = nodeOutputs.indexOf(node)
    if(index < 0)
      nodeOutputs.splice(index, 1)
    if selectedNode == node
      selectedNode = null

  nodeRightClick = (d) ->
    d3.event.preventDefault()
    deleteNode(d)
    update()

  toggleInputNode = () ->
    if(neuronPanelInputSwitch.property("checked"))
      selectedNode.getAssociatedElement().classed("node-input", true)
      nodeInputs.push(selectedNode)
    else
      selectedNode.getAssociatedElement().classed("node-input", false)
      nodeInputs.slice(nodeInputs.indexOf(selectedNode), 1)
      
  toggleOutputNode = () ->
    if(neuronPanelOutputSwitch.property("checked"))
      selectedNode.getAssociatedElement().classed("node-output", true)
      nodeOutputs.push(selectedNode)
    else
      selectedNode.getAssociatedElement().classed("node-output", false)
      nodeInputs.slice(nodeOutputs.indexOf(selectedNode), 1)

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
    .text((d) -> "Bias:" + d.bias)
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
    nodeSelection.exit().remove()

  updateEdges = () ->
    edgeSelection = edgesG.selectAll("g").data(myEdges, (d) -> d.start.id + "+" + d.finish.id)
    enterEdgeSelection = edgeSelection.enter().append("g")
    enterEdgeSelection.append("path")
      .style("marker-end", "url(#edge-arrow)")
      .classed("link", true)
    enterEdgeSelection.append("text").append("textPath")
    .attr("xlink:href", (d,i) -> "#linkId_" + i)
    edgeSelection.select("path")
      .attr("id", (d,i) -> "linkId_" + i)
      .attr("d", (d) -> generatePath(d.start.x, d.start.y, d.finish.x, d.finish.y))
    edgeSelection.select("text")
      .attr("text-anchor", "end")
      .attr("dx", (d) ->
        # Get the length of the path
        distance = Math.sqrt(Math.pow(d.start.x - d.finish.x, 2) + Math.pow(d.start.y - d.finish.y, 2))
        return distance - 100
      )
      .attr("dy", "-10")
      .attr("fill", "#333")
    edgeSelection.select("textPath")
    .text((d) -> "W:" + d.finish.inputWeights[d.finish.inputs.indexOf(d)])
    edgeSelection
    .attr("id", (d) -> "edge_" + d.id)
    edgeSelection.exit().remove()

  clearPanel = () ->
    neuronPanelBiasInput.attr("type", "hidden")
    selectedNodeData.inputWeights = []
    selectedNodeData.bias = 0
    neuronPanelInputRow.style("display", "none")
    neuronPanelInputSwitch.property("checked", false)
    neuronPanelOutputRow.style("display", "none")
    neuronPanelOutputSwitch.property("checked", false)
    updatePanel()

  showPanel = () ->
    selectedNodeData.inputWeights = selectedNode.inputWeights
    selectedNodeData.bias = selectedNode.bias
    neuronPanelBiasInput.attr("type", "text")
    neuronPanelBiasInput.property("value", selectedNodeData.bias)
    # Check to see if we should enable the checkboxes
    if selectedNode.inputs.length == 0
      neuronPanelInputRow.style("display", "table-row")
      neuronPanelInputSwitch.property("checked", nodeInputs.indexOf(selectedNode) != -1)
    else
      neuronPanelInputRow.style("display", "none")
      neuronPanelInputSwitch.property("checked", false)
    if selectedNode.outputs.length == 0
      neuronPanelOutputRow.style("display", "table-row")
      neuronPanelOutputSwitch.property("checked", nodeOutputs.indexOf(selectedNode) != -1)
    else
      neuronPanelOutputRow.style("display", "none")
      neuronPanelOutputSwitch.property("checked", false)
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

  return network

$ ->
  myNetwork = Network()
  myNetwork("#neuron", [], [])
