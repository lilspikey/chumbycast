import List

class ChumbyCast extends MovieClip {	
	var itemsList:MovieClip;
	var pipeURL:String;
	var contentDisplay:MovieClip;
	var contentHTMLField:TextField;
	
	function onLoad() {
		var itemsList:MovieClip = this.attachMovie('list', 'itemsList', this.getNextHighestDepth());
		this.itemsList=itemsList;
		
		var test_handler:Function = function() {
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
		itemsList.addItem("ten");
	}
	
}