
class List extends MovieClip {
	var items:Array;
	var selected:Number;
	var list_width:Number;
	var list_height:Number;
	var prev_y:Number;
	var mouse_down:Boolean;
	var auto_scroll_down:Boolean;
	var auto_scroll_wait:Number;
	
	function List() {
		if ( !this.list_width ) {
			this.list_width = 320;
		}
		if ( !this.list_height ) {
			this.list_height = 240;
		}
		this.items = [];
		this.selected=-1;
		this.prev_y=-1;
		this.mouse_down=false;
		this.auto_scroll_down=true;
		this.auto_scroll_wait=20;
	}
	
	function onLoad() {
		// use a mask so the main image is never larger
		// then the width/height we want
		var mask:MovieClip = this.createEmptyMovieClip("mask", this.getNextHighestDepth());
		mask.beginFill(0x000000);
		mask.moveTo(0,0);
		mask.lineTo(this.list_width, 0);
		mask.lineTo(this.list_width, this.list_height);
		mask.lineTo(0, this.list_height);
		mask.lineTo(0,0);
		mask.endFill();
		this.setMask(mask);
		
		var self:MovieClip = this;
		setInterval(function() { self.autoScroll() }, 100);
	}
	
	function drawItem(item:MovieClip,highlight:Boolean) {
		var width:Number  = item.item_width;
		var height:Number = item.item_height;
	
		var color:Number = highlight? 0xFFFFFF : 0xCCCCCC;
	
		item.clear();
		item.beginFill(color);
		item.lineStyle(0, color);
		item.moveTo(0,0);
		item.lineTo(width, 0);
		item.lineTo(width, height);
		item.lineTo(0, height);
		item.lineTo(0,0);
		item.endFill();
		
		item.lineStyle(1, 0x000000);
		item.moveTo(0, height-1);
		item.lineTo(width, height-1);
	}
	
	function autoScroll() {
		if ( !this.mouse_down ) {
			this.auto_scroll_wait--;
			if ( this.auto_scroll_wait >= 0 ) {
				return;
			}
			var dy:Number = this.auto_scroll_down? -1: 1;
			if ( Math.abs(scrollItems(dy)) <= 0.1 ) {
				this.auto_scroll_down = !this.auto_scroll_down;
				this.auto_scroll_wait=10;
			}
		}
	}
	
	function scrollItems(dy:Number):Number {
		if ( this.items.length > 0 ) {
			// make sure we can't scroll past top/bottom
			if ( dy > 0 ) {
				var top_y:Number = this.items[0]._y;
				dy = Math.min(dy, Math.abs(top_y));
			}
			else if ( dy < 0 ) {
				var last:MovieClip = this.items[this.items.length-1];
				var bottom_y:Number = last._y + last._height;
				if ( bottom_y > this.list_height ) {
					dy = -Math.min(Math.abs(dy), Math.abs(this.list_height - bottom_y));
				}
				else {
					dy = 0;
				}
			}
		}
		
		for ( var i:Number = 0; i < this.items.length; i++ ) {
			var y:Number = this.items[i]._y + dy;
			this.items[i]._y = y;
		}
		
		return dy;
	}
	
	function createItem(label:String):MovieClip {
		var item:MovieClip = this.createEmptyMovieClip("item_"+this.items.length, this.getNextHighestDepth());
		var textField:TextField = item.createTextField("textField", item.getNextHighestDepth(), 0, 0, this.list_width, 0);
		item.textField.embedFonts = true;
		item.textField.text=label;
		item.textField.wordWrap=true;
		item.textField.multiline=true;
		item.textField.autoSize=true;
		
		var style_fmt:TextFormat = new TextFormat();
		style_fmt.font = "main_font";
		style_fmt.size = 14;
		item.textField.setTextFormat(style_fmt);
		
		return item;
	}
	
	function setSelected(selected:Number) {
		var prev_selected = this.selected;
		if ( prev_selected >= 0 && prev_selected < this.items.length ) {
			this.drawItem(items[prev_selected], false);
		}
		
		this.selected = selected;
		if ( selected >= 0 && selected < this.items.length ) {
			this.drawItem(items[selected], true);
		}
	}
	
	function clearItems() {
		this.selected = -1;
		for ( var i:Number = 0; i < this.items.length; i++ ) {
			var item:MovieClip = this.items[i];
			item.removeMovieClip();
		}
		this.items=[];
	}
	
	function addItem(label:String, listener:Function) {
		var y:Number = 0;
		for ( var i:Number = 0; i < this.items.length; i++ ) {
			var item = this.items[i];
			y = Math.max(y, item._y + item._height);
		}
		
		var item:MovieClip = createItem(label);
		
		item._x = 0;
		item._y = y;
		item.item_width  = this.list_width;
		
		// do this twice to ensure things get laid out
		// correctly
		for ( var i:Number = 0; i < 2; i++ ) {
			item.item_height = Math.round(item._height);
			this.drawItem(item, false);
		}
		
		var index:Number = this.items.length;
		
		var self:MovieClip = this;
		
		item.onPress = function() {
			self.setSelected(index);
			self.mouse_down=true;
			self.prev_y=self._ymouse;
			self.auto_scroll_wait=20;
		};
		
		item.onMouseMove = function() {
			if ( self.mouse_down ) {
				var dy:Number = self._ymouse - self.prev_y;
				self.prev_y = self._ymouse;
				self.scrollItems(dy);
				if ( dy > 2 ) {
					self.setSelected(-1);
				}
			}
		}
		
		item.onReleaseOutside = function() {
			self.setSelected(-1);
			self.mouse_down=false;
		};
		
		item.onRelease = function() {
			self.mouse_down=false;
			if ( listener ) {
				listener();
			}
		};
		
		this.items.push(item);
	}
	
}