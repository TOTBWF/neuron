Network = () ->
  # Store list of node and edge data
  myNodes = [{id: 0, x:100, y:100}]
  myEdges = []
  # Hold SVG Groups for edges and nodes
  nodesG = null
  edgesG = null
  # Container Elements
  neuronContainer = null;
  neuronSvg = null;
  # Drag behaviour
  nodeDrag = d3.behavior.drag()
    .origin (d) ->
      return d
    .on "drag", (d) ->
      d.x = d3.event.x
      d.y = d3.event.y
      console.log(d)
      d3.select(this).attr("cx", d.x).attr("cy", d.y)

  network = (container, nodes, edges) ->
    neuronContainer = d3.select(container)
    neuronSvg = neuronContainer.append("svg")
    .attr("width", "100%")
    .attr("height", "100%")
    nodesG = neuronSvg.append("g").attr("id", "nodes")
    edgesG = neuronSvg.append("g").attr("id", "edges")
    neuronSvg.on('click', svgClick)
    updateGraph()
    
  svgClick = () ->
    return if d3.event.defaultPrevented
    coords = d3.mouse(neuronSvg.node())
    node = {id: myNodes.length, x:coords[0], y:coords[1]};
    myNodes.push(node)
    updateGraph()
  

  updateGraph = () ->
    selection = nodesG.selectAll("circle").data(myNodes)
    selection.enter().append("circle")
      .attr("id", (d) -> d.id)
      .attr("cx", (d) -> d.x + "px")
      .attr("cy", (d) -> d.y + "px")
      .attr("r", "40")
      .attr("fill", "white")
      .attr("stroke", "black")
      .attr("stroke-width", "3")
      .call(nodeDrag)
  return network

$ ->
  myNetwork = Network()
  myNetwork("#neuron", [], [])
