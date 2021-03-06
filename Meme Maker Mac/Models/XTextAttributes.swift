//
//  XTextAttributes.swift
//  Meme Maker
//
//  Created by Avikant Saini on 4/6/16.
//  Copyright © 2016 avikantz. All rights reserved.
//

import AppKit
import Foundation

class XTextAttributes: NSObject {
	
	var text: NSString! = ""
	var uppercase: Bool = true

	var rect: CGRect = CGRectZero
	var offset: CGPoint = CGPointZero
	
	var fontSize: CGFloat = 44
	var font: NSFont = NSFont(name: "Impact", size: 44)!
	
	var textColor: NSColor = NSColor.whiteColor()
	var outlineColor: NSColor = NSColor.blackColor()
	
	var alignment: NSTextAlignment = .Center
	var absAlignment: Int {
		set (absA) {
			switch absA {
				case 0: alignment = .Left
					break;
				case 2: alignment = .Right
					break;
				case 3: alignment = .Justified
					break;
				default: alignment = .Center
					break;
			}
		}
		get {
			switch alignment {
				case .Left: return 0
				case .Right: return 2
				case .Justified: return 3
				default: return 1
			}
		}
	}
	
	var strokeWidth: CGFloat = 2
	
	var opacity: CGFloat = 1
	
	var shadowEnabled: Bool = true
	var shadow3D: Bool = false
	
	init(savename: String) {
		
		super.init()
		
		do {
			
			text = ""
			rect = CGRectZero
			setDefault()
			
			if (!NSFileManager.defaultManager().fileExistsAtPath(documentsPathForFileName(savename))) {
//				print("No such attribute file")
				return
			}
			
			if let data = NSData.init(contentsOfFile: documentsPathForFileName(savename)) {
				
				let dict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
				
//				print("\(savename) = \(dict)")
				
				text = dict["text"] as! NSString
				uppercase = dict["uppercase"] as! Bool
				
				rect = NSRectFromString(dict["rect"] as! String)
				offset = NSPointFromString(dict["offset"] as! String)
				
				fontSize = dict["fontSize"] as! CGFloat
				let fontName = dict["fontName"] as! String
				font = NSFont(name: fontName, size: fontSize)!
				
				if let textRGB = dict["textColorRGB"] as? [String: AnyObject] {
					textColor = NSColor(red: textRGB["red"] as! CGFloat, green: textRGB["green"] as! CGFloat, blue: textRGB["blue"] as! CGFloat, alpha: 1)
				}
				
				if let outRGB = dict["outColorRGB"] as? [String: AnyObject] {
					outlineColor = NSColor(red: outRGB["red"] as! CGFloat, green: outRGB["green"] as! CGFloat, blue: outRGB["blue"] as! CGFloat, alpha: 1)
				}
				
				let align = dict["alignment"] as! Int
				switch align {
					case 0: alignment = .Center
					case 1: alignment = .Justified
					case 2: alignment = .Left
					case 3: alignment = .Right
					default: alignment = .Center
				}
				
				strokeWidth = dict["strokeWidth"] as! CGFloat
				
				opacity	= dict["opacity"] as! CGFloat
				
				shadowEnabled = dict["shadowEnabled"] as! Bool
				shadow3D = dict["shadow3D"] as! Bool
				
			}
		} catch _ {
			print("attribute reading failed")
		}
		
	}
	
	func saveAttributes(savename: String) -> Bool {
		
		let dict = NSMutableDictionary()
		
		dict["text"] = text
		dict["uppercase"] = NSNumber(bool: uppercase)
		
		dict["rect"] = NSStringFromRect(rect)
		dict["offset"] = NSStringFromPoint(offset)
		
		let fontName = font.fontName
		let fontSizeNum = NSNumber(float: Float(fontSize))
		dict["fontSize"] = fontSizeNum
		dict["fontName"] = fontName
		
		if let ntextColor = textColor.colorUsingColorSpaceName(NSDeviceRGBColorSpace) {
			let textRGB = ["red": ntextColor.redComponent, "green": ntextColor.greenComponent, "blue": ntextColor.blueComponent]
			dict["textColorRGB"] = textRGB
		}
		
		if let noutColor = outlineColor.colorUsingColorSpaceName(NSDeviceRGBColorSpace) {
			let outRGB = ["red": noutColor.redComponent, "green": noutColor.greenComponent, "blue": noutColor.blueComponent]
			dict["outColorRGB"] = outRGB
		}
		
		var align: Int = 0
		switch alignment {
			case .Justified: align = 1
			case .Left: align = 2
			case .Right: align = 3
			default: align = 0
		}
		dict["alignment"] = NSNumber(integer: align)
		
		dict["strokeWidth"] = NSNumber(float: Float(strokeWidth))
		
		dict["opacity"] = NSNumber(float: Float(opacity))
		
		dict["shadowEnabled"] = NSNumber(bool: shadowEnabled)
		dict["shadow3D"] = NSNumber(bool: shadow3D)
		
//		print("SAVING : \(savename) = \(dict)")
		
		do {
			let data = try NSJSONSerialization.dataWithJSONObject(dict, options: .PrettyPrinted)
			try data.writeToFile(documentsPathForFileName(savename), options: .AtomicWrite)
		} catch _ {
			print("attribute writing failed")
		}
		
		return true
		
	}
	
	func resetOffset() -> Void {
		offset = CGPointZero
		fontSize = 44
	}
	
	func setDefault() -> Void {
		uppercase = true
		offset = CGPointZero
		fontSize = 44
		font = NSFont(name: "Impact", size: fontSize)!
		textColor = NSColor.whiteColor()
		outlineColor = NSColor.blackColor()
		alignment = .Center
		strokeWidth = 2
		opacity = 1
	}
	
	func getTextAttributes() -> [String: AnyObject] {
		
		var attr: [String: AnyObject] = [:]
		
		font = NSFont(name: font.fontName, size: fontSize)!
		attr[NSFontAttributeName] = font
		
		attr[NSForegroundColorAttributeName] = textColor.colorWithAlphaComponent(opacity)
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.maximumLineHeight = fontSize
		paragraphStyle.alignment = alignment
		
		attr[NSParagraphStyleAttributeName] = paragraphStyle
		
		attr[NSStrokeWidthAttributeName] = NSNumber(float: Float(-strokeWidth))
		
		attr[NSStrokeColorAttributeName] = outlineColor
		
		if (shadowEnabled) {
			let shadow = NSShadow()
			shadow.shadowColor = outlineColor
			if (shadow3D) {
				shadow.shadowOffset = CGSizeMake(0, -1)
				shadow.shadowBlurRadius = 1.5
			} else {
				shadow.shadowOffset = CGSizeMake(0.1, 0.1)
				shadow.shadowBlurRadius = 0.8
			}
			attr[NSShadowAttributeName] = shadow
		}
		
		return attr
		
	}
	
	class func clearTopAndBottomTexts() -> Void {
		// We don't want text to retain when selecting new meme?
		let topTextAttr = XTextAttributes(savename: "topAttr")
		topTextAttr.text = ""
		topTextAttr.setDefault()
		topTextAttr.saveAttributes("topAttr")
		let bottomTextAttr = XTextAttributes(savename: "bottomAttr")
		bottomTextAttr.text = ""
		bottomTextAttr.setDefault()
		bottomTextAttr.saveAttributes("bottomAttr")
	}
	
}
