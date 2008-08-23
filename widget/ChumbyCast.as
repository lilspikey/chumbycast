import Json

class ChumbyCast extends MovieClip {	
	var itemsList:MovieClip;
	var selectedURL:String;
	var statusField:TextField;
	var statusTextFormat:TextFormat;
	var playButton:MovieClip;
	var stopButton:MovieClip;
	var refreshButton:MovieClip;
	
	function onLoad() {
		createList(0, 0, 320, 200);
		createControls(0, 201, 320, 38);
		loadList();
	}
	
	function createList(x:Number, y:Number, width:Number, height:Number) {
		var itemsList:MovieClip = this.attachMovie('list', 'itemsList', this.getNextHighestDepth(), { _y: x+1, _x: y+1, list_height: height, list_width:width-2 });
		this.itemsList=itemsList;
		
		this.lineStyle(1, 0x333333);
		this.beginFill(0xCCCCCC);
		this.moveTo(x, y);
		this.lineTo(x+width-1, y);
		this.lineTo(x+width-1, y+height+1);
		this.lineTo(x,         y+height+1);
		this.lineTo(x, y);
		this.endFill();
	}
	
	function createControls(x:Number, y:Number, width:Number, height:Number) {
		this.statusField = this.createTextField("statusField", this.getNextHighestDepth(), x+width/2, y+20, width/2, height);
		this.statusTextFormat = new TextFormat();
		this.statusTextFormat.font = "main_font";
		this.statusTextFormat.size = 12;
		this.statusTextFormat.align = "right";
		
		this.statusField.setTextFormat(this.statusTextFormat);
		this.statusField.embedFonts = true;
		
		this.showMessage("");
		
		this.lineStyle(1, 0x333333);
		this.beginFill(0xFFFF99);
		this.moveTo(x, y);
		this.lineTo(x+width-1, y);
		this.lineTo(x+width-1, y+height);
		this.lineTo(x,         y+height);
		this.lineTo(x, y);
		this.endFill();
		
		var self:MovieClip = this;
		
		playButton = this.attachMovie('play', 'playButton', this.getNextHighestDepth(), { _x: x+3, _y: y+3 })
		playButton.onRelease = function() {
			self.play();
		};
		
		stopButton = this.attachMovie('stop', 'stopButton', this.getNextHighestDepth(), { _x: x+3+32+6, _y: y+3 });
		stopButton.onRelease = function() {
			self.stop();
		};
		
		refreshButton = this.attachMovie('refresh', 'refreshButton', this.getNextHighestDepth(), { _x: x+3+32+6+32+6, _y: y+3 });
		refreshButton.onRelease = function() {
			self.refresh();
		};
	}
	
	function populateList(data:String) {
		var json:JSON = new JSON();
		var json_data:Object = json.parse(data);
		
		itemsList.clearItems();
		for ( var i:Number = 0; i < json_data.length; i++ ) {
			var title:String = json_data[i][1];
			var url:String = json_data[i][2];
			var played:Boolean = json_data[i][3];
			this.addItem(title, url, played);
		}
		this.showMessage("");
	}
	
	function addItem(title:String, url:String, played:Boolean) {
		var self:MovieClip = this;
		itemsList.addItem(title,
			function() {
				self.selectedURL = url;
			}
		);
	}
	
	function play() {
		this.showMessage("Playing... ");
	}
	
	function stop() {
		this.showMessage("Stopping... ");
	}
	
	function refresh() {
		this.showMessage("Refreshing... ");
	}
	
	function showMessage(message:String) {
		this.statusField.text = message;
		this.statusField.setTextFormat(this.statusTextFormat);
	}
	
	function loadList() {
		this.showMessage("Loading... ");
		var self:MovieClip = this;
		var loader:LoadVars = new LoadVars();
		loader.onData = function(data:String) {
			if ( data ) {
				self.populateList(data);
			}
			else {
				self.showMessage("error loading");
			}
		};
		loader.load("http://localhost:3142/list");
	}
	
}