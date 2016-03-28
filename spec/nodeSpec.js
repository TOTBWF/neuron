(function() {
  describe("Node", function() {
    var currentID, node;
    node = null;
    currentID = 0;
    beforeAll(function() {
      currentID = Node.currentID;
      return node = new Node(0, 0);
    });
    return it("Test Node Setup", function() {
      return expect(node.id).toEqual(currentID);
    });
  });

}).call(this);
