// JavaScript code for handling interactivity

// Fetch data when the dataset selection changes
document.getElementById('dataset').addEventListener('change', fetchData);

// Fetch data when the page loads
window.onload = fetchData;

// Function to fetch data from the API and render it
function fetchData() {
  var dataset = document.getElementById('dataset').value;
  var url = `https://connect.cynkra.com/sgods-api/data?dataset=${dataset}&format=json`;

  fetch(url)
    .then(response => response.json())
    .then(data => {
      renderTable(data);
    })
    .catch(error => {
      console.error('Error fetching data:', error);
      document.getElementById('dataTable').innerHTML = '<p>Failed to fetch data.</p>';
    });
}

function renderTable(data) {
  if (!Array.isArray(data) || data.length === 0) {
    $('#dataTable').html('<p>No data available.</p>');
    return;
  }

  // Destroy existing table if it exists
  if ($.fn.DataTable.isDataTable('#dataTable table')) {
    $('#dataTable table').DataTable().destroy();
  }

  // Clear the dataTable div
  $('#dataTable').empty();

  // Create table element
  var table = $('<table id="dataTableTable" class="display" width="100%"></table>');
  $('#dataTable').append(table);

  // Initialize DataTable
  $('#dataTableTable').DataTable({
    data: data,
    columns: Object.keys(data[0]).map(function(key) {
      return { title: key, data: key };
    })
  });
}

// Handle data download
document.getElementById('downloadButton').addEventListener('click', function() {
  var dataset = document.getElementById('dataset').value;
  var format = document.getElementById('format').value;
  var url = `https://connect.cynkra.com/sgods-api/data?dataset=${dataset}&format=${format}`;
  window.location.href = url;
});
