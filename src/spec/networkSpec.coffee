describe("Network", () ->
  # Variables
  network = null
  node1 = null
  node2 = null
  node3 = null
  node4 = null
  
  # Basic setup of the node object
  beforeEach(() ->
    network = new Network()
    node1 = new Node(1, 0)
    node2 = new Node(2, 0)
    node3 = new Node(3, 0)
    node4 = new Node(4, 0)
  )
  
  describe("Test basic functionality", () ->
    it("Test Network creation", () ->
      expect(network.nodes.length).toEqual(0)
      expect(network.edges.length).toEqual(0)
      expect(network.inputNodes.length).toEqual(0)
      expect(network.outputNodes.length).toEqual(0)
      expect(network.selectedNode).toBeNull()
    )
    
    it("Test indexing nodes by ids", () -> 
      network.nodes = [node1, node2, node3]
      expect(network.indexNodesById(node1.id)).toEqual(node1)
      expect(network.indexNodesById(node3.id)).toEqual(node3)
      expect(network.indexNodesById(node4.id)).toBeNull()
  )
  )

  describe("Test node deletion", () -> 
    beforeEach(() ->
      network.nodes = [node1, node2, node3, node4]
      network.createEdge(node2, node1)
      network.createEdge(node4, node1)
      network.createEdge(node4, node3)
      for edge in network.edges
        do (edge) ->
          network.setIONodeStatus(edge)
    )
    it("Test deleting a node from a specific list", () ->
      expect(network.deleteNodeFromList(network.inputNodes, node2)).toEqual(true)
      expect(network.inputNodes.indexOf(node2)).toEqual(-1)
      length = network.inputNodes.length;
      expect(network.deleteNodeFromList(network.inputNodes, node3)).toEqual(false)
      expect(network.inputNodes.length).toEqual(length)
    )
    
    it("Test deleting node from network", () ->
      node5 = new Node(5,0)
      network.nodes.push(node5)
      network.createEdge(node3, node5)
      network.setIONodeStatus(network.edges[network.edges.length - 1])
      # Test deleting node with only inputs
      network.deleteNode(node2)
      expect(network.nodes.indexOf(node2)).toEqual(-1)
      expect(network.inputNodes.indexOf(node2)).toEqual(-1)
      for badEdge in node2.outputs.concat(node2.inputs)
        expect(network.edges.indexOf(badEdge)).toEqual(-1)
      # Test deleting node with only outputs
      network.deleteNode(node1)
      expect(network.nodes.indexOf(node1)).toEqual(-1)
      expect(network.outputNodes.indexOf(node1)).toEqual(-1)
      for badEdge in node1.outputs.concat(node1.inputs)
        expect(network.edges.indexOf(badEdge)).toEqual(-1)
      # Test deleting input with inputs and outputs
      network.deleteNode(node3)
      expect(network.nodes.indexOf(node3)).toEqual(-1)
      for badEdge in node3.outputs.concat(node3.inputs)
        expect(network.edges.indexOf(badEdge)).toEqual(-1)

    )
  )

  describe("Test Edge Creation", () ->
    
    beforeEach(() ->
      network.nodes = [node1, node2, node3]
    )
    it("Test creating an edge between 2 nodes", () ->
      # node1 -> node2
      expect(network.createEdge(node1, node2)).toEqual(true)
      expect(network.edges.length).toEqual(1)
      # node2 -> node3
      expect(network.createEdge(node2, node3)).toEqual(true)
      expect(network.edges.length).toEqual(2)
    )
    it("Test creating a cyclic graph", () ->
      # node3 -> node1, cyclical
      network.createEdge(node1, node2)
      network.createEdge(node2, node3)
      expect(network.createEdge(node3, node1)).not.toEqual(true)
      expect(network.edges.length).toEqual(2)
    )
  )   
  
  describe("Test Setting IO Node Status", () -> 
    
    beforeEach(() ->
      network.nodes = [node1, node2, node3, node4]
    )
    
    it("Test setting node as an input", () ->
      network.setInputNodeStatus(node1)
      expect(network.inputNodes[network.inputNodes.length - 1]).toEqual(node1)
      # Test with valid input edge
      network.createEdge(node2, node3)
      network.setInputNodeStatus(node2)
      expect(network.inputNodes[network.inputNodes.length - 1]).toEqual(node2)
      # Make sure that nodes with inputs cant be inputs themselves
      network.setInputNodeStatus(node3)
      expect(network.inputNodes[network.inputNodes.length - 1]).not.toEqual(node3)
    )
    
    it("Test setting node as an output", () ->
      network.setOutputNodeStatus(node1)
      expect(network.outputNodes[network.outputNodes.length - 1]).toEqual(node1)
      # Test with valid output edge
      network.createEdge(node2, node3)
      network.setOutputNodeStatus(node3)
      expect(network.outputNodes[network.outputNodes.length - 1]).toEqual(node3)
      # Make sure that nodes with outputs cant be outputs themselves
      network.setOutputNodeStatus(node2)
      expect(network.outputNodes[network.outputNodes.length - 1]).not.toEqual(node2)
    )
    
    it("Test setting IO Node status", () ->
      network.createEdge(node1, node2)
      network.createEdge(node2, node3)
      edge1_2 = network.edges[0]
      edge2_3 = network.edges[1]
      network.setIONodeStatus(edge1_2)
      network.setIONodeStatus(edge2_3)
      expect(network.inputNodes.indexOf(node1)).not.toEqual(-1)
      expect(network.outputNodes.indexOf(node3)).not.toEqual(-1)
      expect(network.outputNodes.indexOf(node2)).toEqual(-1)
      expect(network.inputNodes.indexOf(node2)).toEqual(-1)
      network.createEdge(node3, node4)
      expect(network.outputNodes.indexOf(node4)).not.toEqual(-1)
      expect(network.outputNodes.indexOf(node3)).toEqual(-1)
    )
  )
)
