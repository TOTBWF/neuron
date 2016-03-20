Network = () ->
  # Store list of node and edge data
  myNodes = []
  myEdges = []
  # Hold SVG Groups for edges and nodes
  nodesG = null
  edgesG = null
  neuronContainer = null;
  neuronSvg = null;
  # Maybe don't hardcode but W/E
  network = (container, nodes, edges) ->
    neuronContainer = d3.select(container)
    neuronSvg = neuronContainer.append("svg")
    .attr("width", "100%")
    .attr("height", "100%")
    nodesG = neuronSvg.append("g").attr("id", "nodes")
    edgesG = neuronSvg.append("g").attr("id", "edges")
    neuronSvg.on('mousedown', svgMouseDown)
    update()
  update = () ->
    # private function
  svgMouseDown = () ->
    coords = d3.mouse(neuronSvg.node())
    node = {id: myNodes.length, x:coords[0], y:coords[1]};
    myNodes.push(node)
    updateGraph()

  updateGraph = () ->
    nodesG.selectAll("circle").remove()
    addNode = (node) ->
      console.log("NODE DETAILS:", node);
      nodesG.append("circle")
        .attr("id", node.id)
        .attr("cx", node.x)
        .attr("cy", node.y)
        .attr("r", "40")
        .attr("fill", "white")
        .attr("stroke", "black")
        .attr("stroke-width", "3")
    addNode node for node in myNodes
  return network

$ ->
  myNetwork = Network()
  myNetwork("#neuron", [], [])
