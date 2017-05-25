var tableModel = function() {
    var self = {

        tableObj: null,
        selectedTestName: null,
        graphModel: null,

        selectOneRow: function() {
            var testName = $(this).text();
            graphModel.toggleSeries(testName);
        },

        createTable: function(dataModel, graphModel, inputModel) {
            self.graphModel = graphModel;
            var chartData = dataModel.chartData;
            var tableDataSet = graphModel.getSeriesData();
            var i = 0;

            if (tableDataSet == []) {
                return;
            }

            var columns = [ ];
            columns.push({ title : "No" });
            columns.push({ 
                title : "Test name", 
                createdCell: function(cell, cellData, rowData, rowIndex, colIndex) {
                    if (cellData.length > 90) {
                        cell.title = cellData       
                        $(cell).tooltip( {
                            delay: 0,
                            track: true
                        })
                    }
                    $(cell).on('click', self.selectOneRow);
                }
            });
    
            var dataColumns = chartData[0].data;
            for (i = 0; i < dataColumns.length; i++) {
                var columnOptions = { 
                    title: "#" + dataColumns[i].xLabel,
                    createdCell: function(cell, cellData, rowData, rowIndex, colIndex) {
                        if (cellData === null || typeof cellData === 'undefined') {
                            return
                        }
                        var cellClassName = '';
                        if (inputModel.relativeToBuild) {
                            var col = dataColumns[colIndex-2];
                            var relativeColumnName = '';
                            if (col != null) {
                                relativeColumnName = col.xLabel;
                            }
                            if (relativeColumnName != inputModel.relativeToBuild) {
                                cellClassName = cellData <= 0 ? 'ttp' : 'ttf'
                            }
                        } else if (dataModel.hasTestTimeThresholdData()) { 
                            var testName = rowData[1];
                            var thresholdData = dataModel.testTimeThresholdData[testName];
                            
                            if (!thresholdData) {
                                thresholdData = dataModel.testTimeThresholdData['*'];
                            }
                            if (thresholdData) {
                                if (cellData <= thresholdData.PassedTime) {
                                    cellClassName = 'ttp';
                                } else if (cellData >= thresholdData.FailedTime) {
                                    cellClassName = 'ttf';
                                } else {
                                    cellClassName = 'tti';
                                }
                            }
                        }
                        if (cellClassName) { 
                            $(cell).addClass(cellClassName);
                        }
                    },
                    render: function(data, type, row, meta) {
                        if (data == null) {
                            return data;
                        }
                        if (inputModel.graphUnit == GraphUnitEnum.percent && data !== Infinity && data !== -Infinity) {
                            return data + '%';
                        }
                        return data;
                    },
                    type: (inputModel.graphUnit == GraphUnitEnum.percent ? 'num-fmt' : 'num')
                };
                if (dataColumns[i].xLabel == inputModel.relativeToBuild) {
                    columnOptions.className = 'relativeBuildColumn'
                }
                columns.push(columnOptions)
            }
    
            if (self.tableObj) {
                self.tableObj.fnClearTable();
                self.tableObj.fnDestroy();
            }
            jQuery('#tableContainer').html('<table cellpadding="0" cellspacing="0" border="0" class="display" id="tableData"></table>');
            self.tableObj = jQuery('#tableData').dataTable( {
                data: tableDataSet,
                columns: columns,
                searching: false,
                scrollX: true,
                fixedColumns: {
                    leftColumns: 2
                }
            } ); 
        }
    };
    return self;
}();