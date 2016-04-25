var graphModel = function() {
    var self = {

        graphObj: null,
        graphLinesObj: null,

        toggleSeries: function(testName) {
            var graphLine = self.graphLinesObj.filter(function () { return this.series.name == testName });
            graphLine.find('.label').trigger('click');
        },

        toggleOnSeriesClick: function() {
            var hoverActiveElement = $('#chart .detail div.item.active');
            if (!hoverActiveElement) {
                return;
            }
            var hoverActiveText = hoverActiveElement.text();
            if (!hoverActiveText) {
                return;
            }
                
            var testNameRegex = new RegExp('(.*):.*$')
            var match = hoverActiveText.match(testNameRegex);
            if (match) { 
                self.toggleSeries(match[1]);
            }
        },

        getSeriesData: function() {
            var result = [];
            var lines = self.graphLinesObj;
            var no = 1;
            for (i = 0; i < lines.length; i++) { 
                var line = lines[i];
                if (!line.series.disabled) {
                    var data = line.series.data;
                    var newRow = [ no++, line.series.name ];
                    data.forEach(function (row) {
                        newRow.push(row.y);
                    });
                    result.push(newRow);
                }
            };
            return result;
        },

        createGraph: function(dataModel, inputModel, createTableCallback) {
            var chartData = dataModel.chartData;
            jQuery('#legend').empty();
            jQuery('#chartContainer').html('<div id="preview"></div><div id="y_axis"></div><div id="chart"></div><div id="x_axis"></div>')

            // prepare xLabelMap for proper x labeling
            var xLabelMap = {}
            for (var i = 0; i < chartData.length; i++) {
                var data = chartData[0].data
                for (var j = 0; j < data.length; j++) {
                    xLabelMap[data[j].x] = '#' + data[j].xLabel
                }
            }
    
            self.graphObj = new Rickshaw.Graph( {
                    element: document.getElementById("chart"),
                    width: dataModel.width,
                    height: dataModel.height,
                    preserve: true,
                    renderer: inputModel.graphRenderer,
                    series: chartData,
                    interpolation: 'linear',
                    padding: {top: 0.01, left: 0.015, right: 0.015, bottom: 0.01},
                    min: 'auto'
            })

            self.graphObj.render();

            var preview = new Rickshaw.Graph.RangeSlider( {
                graph: self.graphObj,
                element: document.getElementById('preview'),
            } );

            var hoverDetail = new Rickshaw.Graph.HoverDetail( {
                graph: self.graphObj,
                xFormatter: function(x) {
                    return xLabelMap[x];
                },
                yFormatter: function(y) {
                    if (inputModel.graphUnit == GraphUnitEnum.ms) { 
                        return y + ' ms';
                    } else if (inputModel.graphUnit == GraphUnitEnum.percent) {
                        return y + '%';
                    }
                    return y;
                }
            } );

            var legend = new Rickshaw.Graph.Legend( {
                graph: self.graphObj,
                element: document.getElementById('legend')
            } );

            var highlighter = new Rickshaw.Graph.Behavior.Series.Highlight( {
                graph: self.graphObj,
                legend: legend
            } );

            var shelving = new Rickshaw.Graph.Behavior.Series.Toggle( {
                graph: self.graphObj,
                legend: legend
            } );

            var xAxis = new Rickshaw.Graph.Axis.X( {
                graph: self.graphObj,
                orientation: 'bottom',
                element: document.getElementById('x_axis'),
                tickFormat: function (x) {
	                var offset = 30;
	                var charSizeInPx = 7;
	                var height = 100;
	                if (typeof xLabelMap[x] == 'string'){
	                    height = offset + xLabelMap[x].length * charSizeInPx
	                }
	                d3.select(document.getElementById('x_axis')).selectAll('text')
	                    .attr('style', 'text-anchor: start;');
	                d3.select(document.getElementById('x_axis')).select('svg')
	                    .attr('height', height);
	                return xLabelMap[x];
                }
            } );

            xAxis.render();
                      
            var yAxis = new Rickshaw.Graph.Axis.Y( {
                graph: self.graphObj,
                tickFormat: function (y) {
                    if (y == 0) {
                        return '';
                    }
                    if (inputModel.graphUnit == GraphUnitEnum.ms) { 
                        var seconds = y / 1000;
                        if (seconds > 10 || y % 10 == 0) {
                            return seconds + 's';
                        } else {
                            return seconds.toFixed(2) + 's';
                        }
                    } else if (inputModel.graphUnit == GraphUnitEnum.percent) {
                        return y + '%';
                    }
                },
                orientation:'left',
				element: document.getElementById('y_axis')
            } );

            yAxis.render();

            jQuery('#legend .line .action, #legend .line .label').each(createTableCallback);
            jQuery('#chart').on('click', self.toggleOnSeriesClick);
            self.graphLinesObj = jQuery('#legend .line');
            return self.graphObj;
        }
    };
    return self;
}();