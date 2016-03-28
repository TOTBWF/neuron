(function() {
  var D3Closure, Edge, Network, Node;

  window.Node = Node = (function() {
    Node.currentID = 0;

    function Node(x, y) {
      this.x = x;
      this.y = y;
      this.id = Node.currentID++;
      this.bias = 0;
      this.inputWeights = [];
      this.inputs = [];
      this.outputs = [];
      this.outputValue = 0;
    }

    Node.prototype.getAssociatedElement = function() {
      return d3.select("#node_" + this.id);
    };

    return Node;

  })();

  window.Edge = Edge = (function() {
    function Edge(start_id, finish_id) {
      this.start_id = start_id;
      this.finish_id = finish_id;
    }

    return Edge;

  })();

  window.Network = Network = (function() {
    function Network() {
      this.nodes = [];
      this.edges = [];
      this.inputNodes = [];
      this.outputNodes = [];
      this.selectedNode = null;
    }

    Network.prototype.indexNodesById = function(id) {
      var i, k, ref;
      for (i = k = 0, ref = this.nodes.length - 1; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
        if (this.nodes[i].id === id) {
          return this.nodes[i];
        }
      }
      return null;
    };

    Network.prototype.setIONodeStatus = function(edge) {
      var nodeFinish, nodeStart;
      nodeStart = this.indexNodesById(edge.start_id);
      nodeFinish = this.indexNodesById(edge.finish_id);
      this.setInputNodeStatus(nodeStart);
      this.setOutputNodeStatus(nodeFinish);
      this.deleteNodeFromList(this.inputNodes, nodeFinish);
      return this.deleteNodeFromList(this.outputNodes, nodeStart);
    };

    Network.prototype.setInputNodeStatus = function(node) {
      if (node.inputs.length === 0 && this.inputNodes.indexOf(node) === -1) {
        return this.inputNodes.push(node);
      }
    };

    Network.prototype.setOutputNodeStatus = function(node) {
      if (node.outputs.length === 0 && this.outputNodes.indexOf(node) === -1) {
        return this.outputNodes.push(node);
      }
    };

    Network.prototype.deleteNodeFromList = function(list, node) {
      var index;
      index = list.indexOf(node);
      if (index !== -1) {
        list.splice(index, 1);
        return true;
      } else {
        return false;
      }
    };

    Network.prototype.deleteNode = function(node) {
      var selectedNode;
      this.edges = this.edges.filter((function(_this) {
        return function(edge) {
          var finishNode, startNode;
          if (node.outputs.indexOf(edge) !== -1) {
            finishNode = _this.indexNodesById(edge.finish_id);
            finishNode.inputs.splice(finishNode.inputs.indexOf(edge));
            _this.setInputNodeStatus(finishNode);
            return false;
          } else if (node.inputs.indexOf(edge) !== -1) {
            startNode = _this.indexNodesById(edge.start_id);
            startNode.outputs.splice(startNode.outputs.indexOf(edge));
            _this.setOutputNodeStatus(startNode);
            return false;
          } else {
            return true;
          }
        };
      })(this));
      this.deleteNodeFromList(this.nodes, node);
      this.deleteNodeFromList(this.inputNodes, node);
      this.deleteNodeFromList(this.outputNodes, node);
      if (selectedNode === node) {
        return selectedNode = null;
      }
    };

    Network.prototype.createEdge = function(start, finish) {
      var edge, filteredEdges;
      edge = new Edge(start.id, finish.id);
      filteredEdges = this.edges.filter(function(elem) {
        if (elem.start_id === edge.finish_id && elem.finish_id === edge.start_id) {
          this.edges.splice(this.edges.indexOf(elem), 1);
        }
        return elem.start_id === edge.start_id && elem.finish_id === edge.finish_id;
      });
      if (filteredEdges.length === 0) {
        start.outputs.push(edge);
        finish.inputs.push(edge);
        finish.inputWeights.push(1);
        this.edges.push(edge);
        if (this.isCyclic()) {
          start.outputs.pop();
          finish.inputs.pop();
          finish.inputWeights.pop();
          this.edges.pop();
          return "Graph cannot be cyclic!";
        } else {
          this.setIONodeStatus(edge);
          return true;
        }
      }
    };

    Network.prototype.isCyclic = function() {
      var fn, helper, i, k, l, recStack, ref, ref1, visited;
      visited = [];
      recStack = [];
      fn = function(i) {
        visited[i] = false;
        return recStack[i] = false;
      };
      for (i = k = 0, ref = this.nodes.length - 1; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
        fn(i);
      }
      helper = (function(_this) {
        return function(i) {
          var edge, j, l, len, ref1;
          if (visited[i] === false) {
            visited[i] = true;
            recStack[i] = true;
            ref1 = _this.nodes[i].outputs;
            for (l = 0, len = ref1.length; l < len; l++) {
              edge = ref1[l];
              j = _this.nodes.indexOf(_this.indexNodesById(edge.finish_id));
              if (!visited[j] && helper(j)) {
                return true;
              } else if (recStack[j]) {
                return true;
              }
            }
          }
          recStack[i] = false;
          return false;
        };
      })(this);
      for (i = l = 0, ref1 = this.nodes.length - 1; 0 <= ref1 ? l <= ref1 : l >= ref1; i = 0 <= ref1 ? ++l : --l) {
        if (helper(i)) {
          return true;
        }
      }
      return false;
    };

    Network.prototype.computeResult = function() {
      var computeSigmoid, k, len, outputNode, ref, resolveNode, results;
      computeSigmoid = function(inputs, node) {
        var i, k, ref, sigma;
        if (inputs.length !== node.inputWeights.length) {
          console.error("Input and Input Weight length mismatch on node_", node.id);
          return;
        }
        sigma = 0;
        for (i = k = 0, ref = inputs.length - 1; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
          sigma += inputs[i] * node.inputWeights[i];
        }
        return 1 / (1 + Math.pow(Math.E, sigma - node.bias));
      };
      resolveNode = function(node) {
        var edge, fn, inputs, k, len, ref;
        if (node.inputs.length === 0) {
          return node.bias;
        }
        inputs = [];
        ref = node.inputs;
        fn = function(edge) {
          return inputs.push(resolveNode(indexNodesById(edge.start_id)));
        };
        for (k = 0, len = ref.length; k < len; k++) {
          edge = ref[k];
          fn(edge);
        }
        return computeSigmoid(inputs, node);
      };
      ref = this.outputNodes;
      results = [];
      for (k = 0, len = ref.length; k < len; k++) {
        outputNode = ref[k];
        results.push(outputNode.outputValue = resolveNode(outputNode));
      }
      return results;
    };

    return Network;

  })();

  D3Closure = function() {
    var clearPanel, d3Closure, edgesG, generatePath, mouseDownNode, network, neuronContainer, neuronPanelBias, neuronPanelBiasInput, neuronPanelWeights, neuronSvg, nodeDrag, nodeMouseDown, nodeMouseUp, nodeRightClick, nodesG, selectedNodeData, shiftDrag, shiftDragLine, showPanel, svgDoubleClick, svgMouseDown, svgMouseUp, update, updateEdges, updateNodes, updatePanel;
    network = null;
    selectedNodeData = {};
    mouseDownNode = null;
    shiftDrag = false;
    nodesG = null;
    edgesG = null;
    neuronContainer = null;
    neuronSvg = null;
    neuronPanelWeights = null;
    neuronPanelBias = null;
    neuronPanelBiasInput = null;
    shiftDragLine = null;
    nodeDrag = d3.behavior.drag().origin(function(d) {
      return d;
    }).on("drag", function(d) {
      if (shiftDrag) {
        return shiftDragLine.attr("d", generatePath(d.x, d.y, d3.mouse(neuronSvg.node())[0], d3.mouse(neuronSvg.node())[1]));
      } else {
        d.x = d3.event.x;
        d.y = d3.event.y;
        d3.select(this).select("circle").attr("cx", d.x).attr("cy", d.y);
        d3.select(this).select("text").attr("x", d.x).attr("y", d.y);
        return update();
      }
    });
    d3Closure = function(container) {
      var svgDefs;
      network = new Network();
      neuronContainer = d3.select(container);
      neuronPanelBias = d3.select("#neuron-panel-bias");
      neuronPanelWeights = d3.select("#neuron-panel-weights");
      d3.select("#compute-button").on("click", network.computeResult);
      neuronSvg = neuronContainer.append("svg").attr("class", "neuron-svg");
      svgDefs = neuronSvg.append("svg:defs");
      svgDefs.append("svg:marker").attr("id", "drag-arrow").attr("viewBox", "-5 -5 10 10").attr("refX", "0").attr("refY", "0").attr("markerWidth", "5").attr("markerHeight", "5").attr("markerUnits", "strokeWidth").attr("orient", "auto").append("svg:path").attr("d", "M0 0 m -5 -5 L 5 0 L -5 5 Z");
      svgDefs.append("svg:marker").attr("id", "edge-arrow").attr("viewBox", "-5 -5 10 10").attr("refX", "17").attr("refY", "0").attr("markerWidth", "5").attr("markerHeight", "5").attr("markerUnits", "strokeWidth").attr("orient", "auto").append("svg:path").attr("d", "M0 0 m -5 -5 L 5 0 L -5 5 Z");
      shiftDragLine = neuronSvg.append("svg:path").style("marker-end", "url(#drag-arrow)").attr("class", "link").attr("d", generatePath(0, 0, 0, 0));
      shiftDragLine.classed("hidden", true);
      edgesG = neuronSvg.append("g").attr("id", "edges");
      nodesG = neuronSvg.append("g").attr("id", "nodes");
      neuronSvg.on('dblclick', svgDoubleClick);
      neuronSvg.on("mousedown", svgMouseDown);
      neuronSvg.on("mouseup", svgMouseUp);
      neuronPanelBiasInput = neuronPanelBias.append("input").attr("type", "hidden").attr("id", "input_bias").attr("value", "1").on("input", function() {
        selectedNode.bias = this.value;
        return update();
      });
      return update();
    };
    generatePath = function(x0, y0, x1, y1) {
      return "M " + x0 + " " + y0 + " L " + x1 + " " + y1;
    };
    svgDoubleClick = function() {
      var coords, node;
      if (d3.event.defaultPrevented) {
        return;
      }
      console.log("Double Click!");
      coords = d3.mouse(neuronSvg.node());
      node = new Node(coords[0], coords[1]);
      network.nodes.push(node);
      return update();
    };
    svgMouseDown = function() {
      return clearPanel();
    };
    svgMouseUp = function() {
      if (shiftDrag) {
        shiftDragLine.classed("hidden", true);
        return shiftDrag = false;
      }
    };
    nodeMouseDown = function(d) {
      d3.event.stopPropagation();
      mouseDownNode = d;
      if (d3.event.shiftKey) {
        shiftDrag = true;
        return shiftDragLine.classed('hidden', false).attr("d", generatePath(d.x, d.y, d.x, d.y));
      }
    };
    nodeMouseUp = function(d) {
      var result;
      shiftDrag = false;
      if (!mouseDownNode) {
        return;
      }
      if (mouseDownNode !== d) {
        result = network.createEdge(mouseDownNode, d);
        if (!result) {
          alert(result);
        }
        update();
      } else {
        network.selectedNode = mouseDownNode;
        showPanel();
      }
      return shiftDragLine.classed("hidden", true);
    };
    nodeRightClick = function(d) {
      d3.event.preventDefault();
      deleteNode(d);
      return update();
    };
    updateNodes = function() {
      var enterNodeSelection, nodeSelection;
      nodeSelection = nodesG.selectAll("g").data(network.nodes, function(d) {
        return d.id;
      });
      enterNodeSelection = nodeSelection.enter().append("g").on("contextmenu", nodeRightClick).on("mousedown", nodeMouseDown).on("mouseup", nodeMouseUp).call(nodeDrag);
      enterNodeSelection.append("circle");
      enterNodeSelection.append("text");
      nodeSelection.select("text").text(function(d) {
        return "ID: " + d.id;
      }).attr("x", function(d) {
        return d.x + "px";
      }).attr("y", function(d) {
        return d.y + "px";
      }).attr("text-anchor", "middle").attr("fill", "#333");
      nodeSelection.select("circle").attr("cx", function(d) {
        return d.x + "px";
      }).attr("cy", function(d) {
        return d.y + "px";
      }).attr("r", "40").attr("class", "node");
      nodeSelection.attr("id", function(d) {
        return "node_" + d.id;
      }).classed("node-input", function(d) {
        return network.inputNodes.indexOf(d) !== -1;
      }).classed("node-output", function(d) {
        return network.outputNodes.indexOf(d) !== -1;
      });
      return nodeSelection.exit().remove();
    };
    updateEdges = function() {
      var edgeSelection, enterEdgeSelection;
      edgeSelection = edgesG.selectAll("g").data(network.edges, function(d) {
        return d.start_id + "+" + d.finish_id;
      });
      enterEdgeSelection = edgeSelection.enter().append("g");
      enterEdgeSelection.append("path").style("marker-end", "url(#edge-arrow)").classed("link", true);
      enterEdgeSelection.append("text").append("textPath").attr("xlink:href", function(d, i) {
        return "#linkId_" + i;
      });
      edgeSelection.select("path").attr("id", function(d, i) {
        return "linkId_" + i;
      }).attr("d", function(edge) {
        var finishNode, startNode;
        startNode = network.indexNodesById(edge.start_id);
        finishNode = network.indexNodesById(edge.finish_id);
        return generatePath(startNode.x, startNode.y, finishNode.x, finishNode.y);
      });
      edgeSelection.select("text").attr("text-anchor", "end").attr("dx", function(edge) {
        var distance, finishNode, startNode;
        startNode = network.indexNodesById(edge.start_id);
        finishNode = network.indexNodesById(edge.finish_id);
        distance = Math.sqrt(Math.pow(startNode.x - finishNode.x, 2) + Math.pow(startNode.y - finishNode.y, 2));
        return distance - 100;
      }).attr("dy", "-10").attr("fill", "#333");
      edgeSelection.select("textPath").text(function(edge) {
        var finishNode;
        finishNode = network.indexNodesById(edge.finish_id);
        return "" + finishNode.inputs.indexOf(edge);
      });
      edgeSelection.attr("id", function(d) {
        return "edge_" + d.start_id + "-" + d.finish_id;
      });
      return edgeSelection.exit().remove();
    };
    clearPanel = function() {
      neuronPanelBiasInput.attr("type", "hidden");
      selectedNodeData.inputWeights = [];
      selectedNodeData.bias = 0;
      return updatePanel();
    };
    showPanel = function() {
      selectedNodeData.inputWeights = selectedNode.inputWeights;
      selectedNodeData.bias = selectedNode.bias;
      neuronPanelBiasInput.attr("type", "text");
      neuronPanelBiasInput.property("value", selectedNodeData.bias);
      return updatePanel();
    };
    updatePanel = function() {
      var weightContainer, weightSelection;
      weightSelection = neuronPanelWeights.selectAll("div").data(selectedNodeData.inputWeights);
      weightContainer = weightSelection.enter().append("div").classed("weight-container", true);
      weightContainer.append("label").attr("for", function(d, i) {
        return "input_weight_" + i;
      }).text(function(d, i) {
        return i + ":";
      });
      weightContainer.append("input").attr("type", "input").attr("value", function(d) {
        return d;
      }).attr("id", function(d, i) {
        return "input_weight_" + i;
      }).on("input", function(d, i) {
        selectedNode.inputWeights[i] = this.value;
        return update();
      });
      return weightSelection.exit().remove();
    };
    update = function() {
      updateNodes();
      updateEdges();
      return shiftDragLine.classed("hidden", true);
    };
    return d3Closure;
  };

  $(function() {
    var myD3Closure;
    myD3Closure = D3Closure();
    return myD3Closure('#neuron');
  });

}).call(this);
