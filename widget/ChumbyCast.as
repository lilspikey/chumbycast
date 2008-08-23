import Json

class ChumbyCast extends MovieClip {	
	var itemsList:MovieClip;
	var pipeURL:String;
	var contentDisplay:MovieClip;
	var contentHTMLField:TextField;
	
	function onLoad() {
		var itemsList:MovieClip = this.attachMovie('list', 'itemsList', this.getNextHighestDepth());
		this.itemsList=itemsList;
		
		itemsList.addItem("Loading...");
		
		loadList();
		
		/*var test_handler:Function = function() {
			itemsList.clearItems();
			itemsList.addItem("cleared");
		};
		
		itemsList.addItem("clear", test_handler);
		itemsList.addItem("two");
		itemsList.addItem("three");
		itemsList.addItem("four");
		itemsList.addItem("five");
		itemsList.addItem("six");
		itemsList.addItem("seven");
		itemsList.addItem("eight");
		itemsList.addItem("nine");
		itemsList.addItem("ten");*/
	}
	
	function createList(data:String) {
		this.itemsList.addItem("loaded");
		var json:JSON = new JSON();
		var json_data:Object = json.parse(data);
		
		itemsList.clearItems();
		for ( var i:Number = 0; i < json_data.length; i++ ) {
			var title = json_data[i][1];
			itemsList.addItem(title);
		}
	}
	
	function loadList() {
		var self:MovieClip = this;
		var loader:LoadVars = new LoadVars();
		loader.onData = function(data:String) {
			if ( data ) {
				self.createList(data);
			}
			else {
				self.itemsList.addItem("error loading");
			}
		};
		loader.load("http://localhost:3142/list");
	}
	
}