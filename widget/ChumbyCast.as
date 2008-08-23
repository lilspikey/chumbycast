import Json

class ChumbyCast extends MovieClip {	
	var itemsList:MovieClip;
	var pipeURL:String;
	var contentDisplay:MovieClip;
	var contentHTMLField:TextField;
	
	function onLoad() {
		var width:Number = 320;
		var list_height:Number = 220;
		var itemsList:MovieClip = this.attachMovie('list', 'itemsList', this.getNextHighestDepth(), { _y: 1, _x: 1, list_height: list_height, list_width: width-2 });
		this.itemsList=itemsList;
		
		this.clear();
		this.lineStyle(1, 0x333333);
		this.beginFill(0xCCCCCC);
		this.moveTo(0,0);
		this.lineTo(width-1, 0);
		this.lineTo(width-1, list_height+1);
		this.lineTo(0, list_height+1);
		this.lineTo(0, 0);
		this.endFill();
		
		loadList();
	}
	
	function populateList(data:String) {
		var json:JSON = new JSON();
		var json_data:Object = json.parse(data);
		
		itemsList.clearItems();
		for ( var i:Number = 0; i < json_data.length; i++ ) {
			var title = json_data[i][1];
			itemsList.addItem(title);
		}
	}
	
	function showMessage(message:String) {
		this.itemsList.addItem(message);
	}
	
	function loadList() {
		this.showMessage("Loading...");
		
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