Network = () ->
  # Store list of node and edge data
  myNodes = []
  myEdges = []

  state = {
    mouseDownNode: null,
    shiftDrag: false
  }

  # Keep track of the ID
  currentID = 0;

  # Hold SVG Groups for edges and nodes
  nodesG = null
  edgesG = null

  # Container Elements
  neuronContainer = null;
  neuronSvg = null;

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
    neuronSvg = neuronContainer.append("svg")
    .attr("width", "100%")
    .attr("height", "100%")
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
    update()

  # Svg Mouse Handlers
  svgDoubleClick = () ->
    return if d3.event.defaultPrevented
    coords = d3.mouse(neuronSvg.node())
    node = {id: currentID++, x:coords[0], y:coords[1], inputs:[], outputs:[]};
    myNodes.push(node)
    update()

  svgMouseDown = () ->

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
      edge = {start: mouseDownNode, finish: d}
      # Remove any edges that are the opposite of the new one
      filteredEdges = myEdges.filter((elem) ->
        if elem.start == edge.finish && elem.finish == edge.start
          myEdges.splice(myEdges.indexOf(elem))
        return elem.start == edge.start && elem.finish == edge.finish
      )
      if filteredEdges .length == 0
        # Make sure that the graph doesn't contain cycles
        mouseDownNode.outputs.push(edge)
        d.inputs.push(edge)
        myEdges.push(edge)
        if isCyclic()
          mouseDownNode.outputs.pop()
          d.inputs.pop()
          myEdges.pop()
          alert("Neural Networks Can't Be Cyclic!")
        update()
    shiftDragLine.classed("hidden", true)

  nodeRightClick = (d) ->
    d3.event.preventDefault()
    # Find the offending node and remove it
    index = 0
    while index < myNodes.length
      if  myNodes[index].id == d.id
        # Remove all associated edges via filter
        myEdges = myEdges.filter((edge) ->
          node = myNodes[index]
          if node.outputs.indexOf(edge) < 0 && node.inputs.indexOf(edge) < 0
            return true
        )
        myNodes.splice(index, 1)
        break
      else
        index += 1
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
    .text((d) -> d.id)
      .attr("x", (d) -> d.x + "px")
      .attr("y", (d) -> d.y + "px")
      .attr("fill", "black")
    nodeSelection.select("circle")
      .attr("cx", (d) -> d.x + "px")
      .attr("cy", (d) -> d.y + "px")
      .attr("r", "40")
      .attr("class", "node")
    nodeSelection
      .attr("id", (d) -> d.id)
    nodeSelection.exit().remove()

  updateEdges = () ->
    edgeSelection = edgesG.selectAll("path").data(myEdges, (d) -> d.start.id + "+" + d.finish.id)
    edgeSelection.enter().append("path")
      .style("marker-end", "url(#edge-arrow)")
      .classed("link", true)
    edgeSelection.attr("d", (d) -> generatePath(d.start.x, d.start.y, d.finish.x, d.finish.y))
    edgeSelection.exit().remove()

  # Re-render the graph
  update = () ->
    updateNodes()
    updateEdges()

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
