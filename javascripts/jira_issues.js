function versions(data) {
  console.log("data received o//");
  $.each(data, function(index, version) {
    if(!version.archived) {
      console.log("#" + index + " name=" + version.name);
      $("#versions tbody").prepend(
        "<tr><td>" + ((version.name != undefined) ? version.name : "") + 
        "</td><td>" + ((version.releaseDate != undefined) ? version.releaseDate : "") +
        "</td><td>" + ((version.description != undefined) ? version.description : "") +
        "</td></tr>");
    }
  });
}



