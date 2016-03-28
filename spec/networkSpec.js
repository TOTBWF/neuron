(function() {
  describe("Network", function() {
    var network, node1, node2, node3, node4;
    network = null;
    node1 = null;
    node2 = null;
    node3 = null;
    node4 = null;
    beforeEach(function() {
      network = new Network();
      node1 = new Node(1, 0);
      node2 = new Node(2, 0);
      node3 = new Node(3, 0);
      return node4 = new Node(4, 0);
    });
    describe("Test basic functionality", function() {
      it("Test Network creation", function() {
        expect(network.nodes.length).toEqual(0);
        expect(network.edges.length).toEqual(0);
        expect(network.inputNodes.length).toEqual(0);
        expect(network.outputNodes.length).toEqual(0);
        return expect(network.selectedNode).toBeNull();
      });
      return it("Test indexing nodes by ids", function() {
        network.nodes = [node1, node2, node3];
        expect(network.indexNodesById(node1.id)).toEqual(node1);
        expect(network.indexNodesById(node3.id)).toEqual(node3);
        return expect(network.indexNodesById(node4.id)).toBeNull();
      });
    });
    describe("Test node deletion", function() {
      beforeEach(function() {
        var edge, i, len, ref, results;
        network.nodes = [node1, node2, node3, node4];
        network.createEdge(node2, node1);
        network.createEdge(node4, node1);
        network.createEdge(node4, node3);
        ref = network.edges;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          edge = ref[i];
          results.push((function(edge) {
            return network.setIONodeStatus(edge);
          })(edge));
        }
        return results;
      });
      it("Test deleting a node from a specific list", function() {
        var length;
        expect(network.deleteNodeFromList(network.inputNodes, node2)).toEqual(true);
        expect(network.inputNodes.indexOf(node2)).toEqual(-1);
        length = network.inputNodes.length;
        expect(network.deleteNodeFromList(network.inputNodes, node3)).toEqual(false);
        return expect(network.inputNodes.length).toEqual(length);
      });
      return it("Test deleting node from network", function() {
        var badEdge, i, j, k, len, len1, len2, node5, ref, ref1, ref2, results;
        node5 = new Node(5, 0);
        network.nodes.push(node5);
        network.createEdge(node3, node5);
        network.setIONodeStatus(network.edges[network.edges.length - 1]);
        network.deleteNode(node2);
        expect(network.nodes.indexOf(node2)).toEqual(-1);
        expect(network.inputNodes.indexOf(node2)).toEqual(-1);
        ref = node2.outputs.concat(node2.inputs);
        for (i = 0, len = ref.length; i < len; i++) {
          badEdge = ref[i];
          expect(network.edges.indexOf(badEdge)).toEqual(-1);
        }
        network.deleteNode(node1);
        expect(network.nodes.indexOf(node1)).toEqual(-1);
        expect(network.outputNodes.indexOf(node1)).toEqual(-1);
        ref1 = node1.outputs.concat(node1.inputs);
        for (j = 0, len1 = ref1.length; j < len1; j++) {
          badEdge = ref1[j];
          expect(network.edges.indexOf(badEdge)).toEqual(-1);
        }
        network.deleteNode(node3);
        expect(network.nodes.indexOf(node3)).toEqual(-1);
        ref2 = node3.outputs.concat(node3.inputs);
        results = [];
        for (k = 0, len2 = ref2.length; k < len2; k++) {
          badEdge = ref2[k];
          results.push(expect(network.edges.indexOf(badEdge)).toEqual(-1));
        }
        return results;
      });
    });
    describe("Test Edge Creation", function() {
      beforeEach(function() {
        return network.nodes = [node1, node2, node3];
      });
      it("Test creating an edge between 2 nodes", function() {
        expect(network.createEdge(node1, node2)).toEqual(true);
        expect(network.edges.length).toEqual(1);
        expect(network.createEdge(node2, node3)).toEqual(true);
        return expect(network.edges.length).toEqual(2);
      });
      return it("Test creating a cyclic graph", function() {
        network.createEdge(node1, node2);
        network.createEdge(node2, node3);
        expect(network.createEdge(node3, node1)).not.toEqual(true);
        return expect(network.edges.length).toEqual(2);
      });
    });
    return describe("Test Setting IO Node Status", function() {
      beforeEach(function() {
        return network.nodes = [node1, node2, node3, node4];
      });
      it("Test setting node as an input", function() {
        network.setInputNodeStatus(node1);
        expect(network.inputNodes[network.inputNodes.length - 1]).toEqual(node1);
        network.createEdge(node2, node3);
        network.setInputNodeStatus(node2);
        expect(network.inputNodes[network.inputNodes.length - 1]).toEqual(node2);
        network.setInputNodeStatus(node3);
        return expect(network.inputNodes[network.inputNodes.length - 1]).not.toEqual(node3);
      });
      it("Test setting node as an output", function() {
        network.setOutputNodeStatus(node1);
        expect(network.outputNodes[network.outputNodes.length - 1]).toEqual(node1);
        network.createEdge(node2, node3);
        network.setOutputNodeStatus(node3);
        expect(network.outputNodes[network.outputNodes.length - 1]).toEqual(node3);
        network.setOutputNodeStatus(node2);
        return expect(network.outputNodes[network.outputNodes.length - 1]).not.toEqual(node2);
      });
      return it("Test setting IO Node status", function() {
        var edge1_2, edge2_3;
        network.createEdge(node1, node2);
        network.createEdge(node2, node3);
        edge1_2 = network.edges[0];
        edge2_3 = network.edges[1];
        network.setIONodeStatus(edge1_2);
        network.setIONodeStatus(edge2_3);
        expect(network.inputNodes.indexOf(node1)).not.toEqual(-1);
        expect(network.outputNodes.indexOf(node3)).not.toEqual(-1);
        expect(network.outputNodes.indexOf(node2)).toEqual(-1);
        expect(network.inputNodes.indexOf(node2)).toEqual(-1);
        network.createEdge(node3, node4);
        expect(network.outputNodes.indexOf(node4)).not.toEqual(-1);
        return expect(network.outputNodes.indexOf(node3)).toEqual(-1);
      });
    });
  });

}).call(this);
