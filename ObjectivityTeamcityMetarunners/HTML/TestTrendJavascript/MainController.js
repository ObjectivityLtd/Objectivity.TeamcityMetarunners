var mainController = function() {
    var self = {
        dataModel: null,
        inputModel: null,
        graphModel: null,
        tableModel: null,

        init: function(dataModel, inputModel, graphModel, tableModel) {
            self.dataModel = dataModel;
            self.inputModel = inputModel;
            self.graphModel = graphModel;
            self.tableModel = tableModel;
        },

        showGraphAndTable: function() {
            self.inputModel.refreshModel();

            if (!self.inputModel.validateRelativeToBuild(dataModel.originalChartData)) {
                alert('Invalid relative build number: ' + self.inputModel.relativeToBuild + '. You need to enter either valid build number or a negative value.');
                return;
            }
            var newChartData = [];
            for (var i = 0; i < self.dataModel.originalChartData.length; i++) {
                var testSeries = self.dataModel.originalChartData[i];
                testSeries = self.inputModel.filterTestSeries(testSeries);
                if (testSeries) { 
                    newChartData.push(testSeries);
                }
            }
            if (newChartData.length > 0) {
                self.dataModel.chartData = newChartData;
                self.graphModel.createGraph(self.dataModel, self.inputModel, self.createTableCallback);
                self.tableModel.createTable(self.dataModel, self.graphModel, self.inputModel);
            } else {
                alert('No tests matching specified criteria.');
            }
        },

        createTableCallback: function (index, element) {
            var oldOnClick = element.onclick;
            element.onclick = function(e) {
                oldOnClick(e);
                self.tableModel.createTable(self.dataModel, self.graphModel, self.inputModel);
            }
        },

        toggleSection: function() {
            var currentElement = $(this);
            var nextElement = currentElement.next();
            nextElement.fadeToggle('fast');
            currentElement.find('span:first').toggleClass('sectionVisible sectionHidden');    
            if (nextElement[0].id == 'tableContainer' && nextElement.is(':visible')) {  
                tableModel.tableObj.fnAdjustColumnSizing();  
            }
            return false;
        }
    };
    return self;
}();