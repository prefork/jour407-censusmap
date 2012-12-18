CensusMap = CensusMap || {};

CensusMap.app = (function (cm, d3, queue, topojson) {
  var width = 960,
      height = 500,
      _startYear = '2000',
      _endYear = '2011',
      _counties,
      _summary,
      _index,
      _indexKeys,
      _currFips;

  var path = d3.geo.path();

  var svg = d3.select("#map").append("svg")
    .attr("width", width)
    .attr("height", height);

  function loadData(cb) {
    queue()
      .defer(d3.json, "scripts/data/" + CensusMap.dataFiles.map)
      .defer(d3.json, "scripts/data/" + CensusMap.dataFiles.summary)
      .await(cb);
    /*$.when(
      $.getJSON('scripts/data/' + CensusMap.dataFiles.trie),
      $.getJSON('scripts/data/' + CensusMap.dataFiles.index),
      function (trieArgs, idxArgs) {
        _trie = trieArgs[0];
        _index = idxArgs[0];
        $('#js-cty-finder').typeahead({
          source: CensusMap.app.autocomplete
        });
      }
    );*/
  }

  function plotMap(error, us, summary) {
    var rateById = {};

  //  unemployment.forEach(function(d) { rateById[d.id] = +d.rate; });

    var quantize = d3.scale.quantize()
      .domain([summary.stats[_startYear][_endYear].min, summary.stats[_startYear][_endYear].max])
      .range(d3.range(9).map(function(i) { return "q" + i + "-9"; }));

    svg.append("g")
      .attr("class", "counties")
        .selectAll("path")
        .data(topojson.object(us, us.objects.counties).geometries)
      .enter().append("path")
        .attr("id", function (d) { return "fips-" + pad(d.id);})
        .attr("class", function(d) { return summary.county[pad(d.id)] ? quantize(pctChg(summary, pad(d.id))) : 'q0-9'; })
        .attr("title", function(d) { return summary.county[pad(d.id)] ? summary.county[pad(d.id)].county_name : ""; })
        .attr("d", path);

    svg.append("path")
      .datum(topojson.mesh(us, us.objects.states, function(a, b) { return a.id !== b.id; }))
      .attr("class", "states")
      .attr("d", path);

    _summary = summary;

    _counties = d3.selectAll('.counties path');
    _counties.on("click", clickCounty);
    //  .on("mouseover", mouseoverCounty);
    $('#js-cty-finder').typeahead({source: flattenCounties()});
    $("#js-search").submit(function(e) {
      e.preventDefault();
      var nombre = $("#js-search > input:first").val();
      if(_indexKeys[nombre]) {
        $('.js-charts').show();
        updateCharts(pad(_indexKeys[nombre]));
      } else {
        alert("Whoops, can't find that county!");
      }
      return false;
    });
    $("#js-years").submit(function(e) {
      e.preventDefault();
      var startYr = $("#js-plot-start-year").val();
      var endYr = $("#js-plot-end-year").val();
      if(startYr < endYr && (startYr >= 2000 && endYr <= 2011)) {
        _startYear = startYr;
        _endYear = endYr;
        if(_currFips) {
          updateCharts(_currFips);
        }
        restyleMap();
      } else {
        alert("Whoops, double check those years!");
      }
      return false;
    });
  }

  function plotPopChart(fips, el) {

    $(el).empty();
    var data = [];
    $.each(_summary.county[fips].population, function (k, v) {
      data.push({year: k, population: v});
    });

    console.log(data);

    var yAxisLbl = "population",
        xAxisLbl = "year";

    var margin = {top: 20, right: 20, bottom: 30, left: 70},
        width = $(el).width() - margin.left - margin.right,
        height = 300 - margin.top - margin.bottom;

    var formatPercent = d3.format(".0%");

    var x = d3.scale.ordinal()
      .rangeRoundBands([0, width], .1);

    var y = d3.scale.linear()
      .range([height, 0]);

    var xAxis = d3.svg.axis()
      .scale(x)
      .orient("bottom");

    var yAxis = d3.svg.axis()
      .scale(y)
      .orient("left");

    var svg = d3.select(el).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    x.domain(data.map(function(d) { return d.year; }));
    y.domain([0, d3.max(data, function(d) { return d.population; })]);

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text(yAxisLbl);

    svg.selectAll(".bar")
      .data(data)
      .enter().append("rect")
      .attr("class", "bar")
      .attr("x", function(d) { return x(d.year); })
      .attr("width", x.rangeBand())
      .attr("y", function(d) { return y(d.population); })
      .attr("height", function(d) { return height - y(d.population); });
  }

  function updateCharts(fips) {
    _currFips = fips;
    plotPopChart(fips, '#js-pop-chart');
    $('#js-county-name').text(_summary.county[fips].county_name + ", " + _summary.county[fips].state_name);
    $('#js-pct-change').text((pctChg(_summary, fips)*100).toPrecision(2) + '%');
    $('#js-pct-change').css('color', pctChg(_summary, fips) > 0 ? '#468847' : '#B94A48')
    console.log(pctChg(_summary, fips)*100 + '%');

    $('#js-old-pop').text(_summary.county[fips].population[_startYear]);
    $('#js-new-pop').text(_summary.county[fips].population[_endYear]);

    $('#js-old-year').text(_startYear + ' population');
    $('#js-new-year').text(_endYear + ' population');
  }

  function restyleMap() {
    var quantize = d3.scale.quantize()
      .domain([_summary.stats[_startYear][_endYear].min, _summary.stats[_startYear][_endYear].max])
      .range(d3.range(9).map(function(i) { return "q" + i + "-9"; }));
    _counties.attr("class", function(d) { return _summary.county[pad(d.id)] ? quantize(pctChg(_summary, pad(d.id))) : 'q0-9'; })
    return true;
  }

  function flattenCounties() {
    if(!_index) {
      $.each(_summary.county, function (k, v) {
        _index = _index || [];
        _indexKeys = _indexKeys || {};
        _indexKeys[v.county_name + ', ' + v.state_name] = k;
        _index.push(v.county_name + ', ' + v.state_name);
      });
    }
    return _index;
  }

  function mouseoverCounty(d, i) {
    var fips = d3.select(this).attr('id').split('-')[1];
    console.log(fips);
  }

  function clickCounty(d, i) {
    var fips = d3.select(this).attr('id').split('-')[1];
    $('.js-charts').show();
    updateCharts(fips);
  }

  function pad(str) {
    str = str.toString();
    if(str.length < 5) {
      str = ("0" + str);
      return str;
    } else {
      return str;
    }
  }

  function inTrie(str, trie) {
    if(str.length == 0) {
      return true;
    }
    if(trie[str[0]]) {
      return inTrie(str.slice(1), trie[str[0]]);
    } else {
      return false;
    }
  }

  function pctChg(summary, fips) {
    var n = _endYear,
        o = _startYear;
    if (summary.county[fips]) {
      return (summary.county[fips].population[n] - summary.county[fips].population[o]) / (summary.county[fips].population[o]);
    } else {
      return false;
    }
  }

  return {

    initialize : function (props) {
      if(props && props.startYear && props.endYear) {
        _defaultStartYear = props.startYear;
        _defaultEndYear   = props.endYear;
      }
      loadData(plotMap);
      return true;
    },

    autocomplete : function (query, cb) {
      matchCounty(query, cb);
    }

  }

})(CensusMap, d3, queue, topojson);

CensusMap.app.initialize();
