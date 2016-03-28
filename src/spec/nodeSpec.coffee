describe("Node", () ->
  node = null
  currentID = 0;
  # Basic setup of the node object
  beforeAll(() ->
    currentID = Node.currentID;
    node = new Node(0, 0)
  )

  it("Test Node Setup", () ->
    expect(node.id).toEqual(currentID)
  )

)