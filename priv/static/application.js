function createRoom() {
  var messageBoxRoomInput = document.getElementById("message_box_room_input");
  request = {
    command: "create",
    room: messageBoxRoomInput.value,
  };
  doSend(JSON.stringify(request));
}
function joinRoom() {
  var messageBoxRoomInput = document.getElementById("message_box_room_input");
  request = {
    command: "join",
    room: messageBoxRoomInput.value,
  };
  doSend(JSON.stringify(request));
}

function sendMessage() {
  var messageBoxRoomInput = document.getElementById("message_box_room_input");
  var messageBoxInput = document.getElementById("message_box_input");
  request = {
    room: message_box_room_input.value,
    message: messageBoxInput.value,
  };
  doSend(JSON.stringify(request));
}

/* WebSockets functions */
var wsUri = "ws://" + location.host + "/ws/chat";
var output;
var websocket;
function init() {
  output = document.getElementById("output");
  testWebSocket();
}
function testWebSocket() {
  websocket = new WebSocket(
    wsUri + "?access_token=" + getParameterByName("access_token")
  );
  websocket.onopen = function (evt) {
    onOpen(evt);
  };
  websocket.onclose = function (evt) {
    onClose(evt);
  };
  websocket.onmessage = function (evt) {
    onMessage(evt);
  };
  websocket.onerror = function (evt) {
    onError(evt);
  };
}
function onOpen(evt) {
  writeToScreen("CONNECTED");
  doSend(JSON.stringify({ command: "join" }));
}
function onClose(evt) {
  writeToScreen("DISCONNECTED");
}
function onMessage(evt) {
  response = JSON.parse(evt.data);
  if (isError(response)) {
    writeToScreen(
      '<span style="color: red;">ERROR: ' + response.error + "</span>"
    );
  } else if (isSuccess(response)) {
    writeToScreen(
      '<span style="color: green;">SUCCESS: ' + response.success + "</span>"
    );
  } else if (isSystemMessage(response)) {
    writeToScreen(
      '<span style="color: gray;">' +
        response.room +
        ": " +
        response.message +
        "</span>"
    );
  } else {
    writeToScreen(
      '<span style="color: blue;">' +
        response.room +
        ": (" +
        response.from +
        ") " +
        response.message +
        "</span>"
    );
  }
}
function onError(evt) {
  writeToScreen('<span style="color: red;">ERROR:</span> ' + evt.data);
}
function doSend(message) {
  writeToScreen("SENT: " + message);
  websocket.send(message);
}
function writeToScreen(message) {
  var pre = document.createElement("p");
  pre.style.wordWrap = "break-word";
  pre.innerHTML = message;
  output.appendChild(pre);
}
window.addEventListener("load", init, false);

/* Helper functions */
function isError(response) {
  return response.error != undefined;
}
function isSuccess(response) {
  return response.success != undefined;
}
function isSystemMessage(response) {
  return response.from == undefined;
}
/* From: https://stackoverflow.com/a/5158301 */
function getParameterByName(name) {
  var match = RegExp("[?&]" + name + "=([^&]*)").exec(window.location.search);
  return match && decodeURIComponent(match[1].replace(/\+/g, " "));
}
