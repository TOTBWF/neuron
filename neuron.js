var Network;Network=function(){var t,e,r,n,a,i,d,s,o,u,l,f,c,p,h,g,v,x,m,k,y;a=[];n=[];h={mouseDownNode:null,shiftDrag:false};t=0;c=null;e=null;d=null;s=null;p=null;r=function(t,e,r,n){return"M "+t+" "+e+" L "+r+" "+n};o=d3.behavior.drag().origin(function(t){return t}).on("drag",function(t){if(h.shiftDrag){return p.attr("d",r(t.x,t.y,d3.mouse(s.node())[0],d3.mouse(s.node())[1]))}else{t.x=d3.event.x;t.y=d3.event.y;d3.select(this).select("circle").attr("cx",t.x).attr("cy",t.y);d3.select(this).select("text").attr("x",t.x).attr("y",t.y);return m()}});i=function(t,n,a){var i;d=d3.select(t);s=d.append("svg").attr("width","100%").attr("height","100%");i=s.append("svg:defs");i.append("svg:marker").attr("id","drag-arrow").attr("viewBox","-5 -5 10 10").attr("refX","0").attr("refY","0").attr("markerWidth","5").attr("markerHeight","5").attr("markerUnits","strokeWidth").attr("orient","auto").append("svg:path").attr("d","M0 0 m -5 -5 L 5 0 L -5 5 Z");i.append("svg:marker").attr("id","edge-arrow").attr("viewBox","-5 -5 10 10").attr("refX","17").attr("refY","0").attr("markerWidth","5").attr("markerHeight","5").attr("markerUnits","strokeWidth").attr("orient","auto").append("svg:path").attr("d","M0 0 m -5 -5 L 5 0 L -5 5 Z");p=s.append("svg:path").style("marker-end","url(#drag-arrow)").attr("class","link").attr("d",r(0,0,0,0));p.classed("hidden",true);e=s.append("g").attr("id","edges");c=s.append("g").attr("id","nodes");s.on("dblclick",g);s.on("mousedown",v);s.on("mouseup",x);return m()};g=function(){var e,r;if(d3.event.defaultPrevented){return}e=d3.mouse(s.node());r={id:t++,x:e[0],y:e[1]};a.push(r);return m()};v=function(){};x=function(){if(h.shiftDrag){p.classed("hidden",true);return h.shiftDrag=false}};u=function(t){d3.event.stopPropagation();h.mouseDownNode=t;if(d3.event.shiftKey){h.shiftDrag=true;return p.classed("hidden",false).attr("d",r(t.x,t.y,t.x,t.y))}};l=function(t){var e,r,a;h.shiftDrag=false;a=h.mouseDownNode;if(!a){return}if(h.mouseDownNode!==t){e={start:a,finish:t};r=n.filter(function(t){if(t.start===e.finish&&t.finish===e.start){n.splice(n.indexOf(t))}return t.start===e.start&&t.finish===e.finish});if(r.length===0){n.push(e);console.log(JSON.stringify(n));m()}}return p.classed("hidden",true)};f=function(t){var e;d3.event.preventDefault();e=0;while(e<a.length){if(a[e].id===t.id){a.splice(e,1);break}else{e+=1}}return m()};y=function(){var t,e;e=c.selectAll("g").data(a,function(t){return t.id});t=e.enter().append("g").on("contextmenu",f).on("mousedown",u).on("mouseup",l).call(o);t.append("circle");t.append("text");e.select("text").attr("x",function(t){return t.x+"px"}).attr("y",function(t){return t.y+"px"}).attr("fill","black");e.select("circle").attr("cx",function(t){return t.x+"px"}).attr("cy",function(t){return t.y+"px"}).attr("r","40").attr("fill","white").attr("stroke","black").attr("stroke-width","3");e.attr("id",function(t){return t.id});return e.exit().remove()};k=function(){var t;t=e.selectAll("path").data(n,function(t){return t.start.id+"+"+t.finish.id});t.enter().append("path").style("marker-end","url(#edge-arrow)").classed("link",true);t.attr("d",function(t){return r(t.start.x,t.start.y,t.finish.x,t.finish.y)});return t.exit().remove()};m=function(){y();return k()};return i};$(function(){var t;t=Network();return t("#neuron",[],[])});