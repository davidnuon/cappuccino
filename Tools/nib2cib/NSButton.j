/*
 * NSButton.j
 * nib2cib
 *
 * Portions based on NSButtonCell.m (09/09/2008) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/CPButton.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPRadio.j>

@import "NSCell.j"
@import "NSControl.j"


var _CPButtonBezelStyleHeights = {};

_CPButtonBezelStyleHeights[CPRoundedBezelStyle] = 18;
_CPButtonBezelStyleHeights[CPTexturedRoundedBezelStyle] = 20;
_CPButtonBezelStyleHeights[CPHUDBezelStyle] = 20;

var NSButtonIsBorderedMask = 0x00800000,
    NSButtonAllowsMixedStateMask = 0x1000000,

    // The image position is contained in the third byte, and the values
    // don't really follow much of a pattern.
    NSButtonImagePositionMask = 0xFF0000,
    NSButtonImagePositionShift = 16,
    NSButtonNoImagePositionMask = 0x04,
    NSButtonImageAbovePositionMask = 0x0C,
    NSButtonImageBelowPositionMask = 0x1C,
    NSButtonImageRightPositionMask = 0x2C,
    NSButtonImageLeftPositionMask = 0x3C,
    NSButtonImageOnlyPositionMask = 0x44,
    NSButtonImageOverlapsPositionMask = 0x6C,

    // You cannot set neither highlightsBy nor showsStateBy in IB,
    // but you can set button type which implicitly sets the masks.
    // Note that you cannot set NSPushInCellMask for showsStateBy.
    NSHighlightsByPushInCellMask = 0x80000000,
    NSHighlightsByContentsCellMask = 0x08000000,
    NSHighlightsByChangeGrayCellMask =  0x04000000,
    NSHighlightsByChangeBackgroundCellMask = 0x02000000,
    NSShowsStateByContentsCellMask = 0x40000000,
    NSShowsStateByChangeGrayCellMask = 0x20000000,
    NSShowsStateByChangeBackgroundCellMask = 0x10000000;


@implementation CPButton (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        self = [self NS_initWithCell:cell];
    }

    return self;
}

/*!
    Intialise a button given a cell. This method is meant for reuse by controls which contain
    cells other than CPButton itself.
*/
- (id)NS_initWithCell:(NSCell)cell
{
    var alternateImage = [cell alternateImage],
        positionOffsetSizeWidth = 0,
        positionOffsetOriginX = 0,
        positionOffsetOriginY = 0;

    if ([alternateImage isKindOfClass:[NSButtonImageSource class]])
    {
        /*
            Because CPCheckBox and CPRadio are direct subclasses,
            we can just change the class of this object. In the
            case of CPRadio, we can add its _radioGroup ivar by setting it
            directly on self.

            When swizzling the class, make sure to update the theme
            attributes.
        */
        if ([alternateImage imageName] === @"NSSwitch")
        {
            self.isa = [CPCheckBox class];
        }
        else if ([alternateImage imageName] === @"NSRadioButton")
        {
            self.isa = [CPRadio class];
            self._radioGroup = [CPRadioGroup new];
        }

        _themeClass = [[self class] defaultThemeClass];
        alternateImage = nil;
    }

    NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = self;

    _title = [cell title];
    _alternateTitle = [cell alternateTitle];
    _controlSize = CPRegularControlSize;

    [self setBordered:[cell isBordered]];
    _bezelStyle = [cell bezelStyle];

    // Map Cocoa bezel styles to Cappuccino bezel styles and adjust frame
    switch (_bezelStyle)
    {
        // implemented:
        case CPRoundedBezelStyle:
            positionOffsetOriginY = 6;
            positionOffsetOriginX = 4;
            positionOffsetSizeWidth = -12;
            break;

        case CPTexturedRoundedBezelStyle:
            positionOffsetOriginY = 2;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            break;

        case CPHUDBezelStyle:
            break;

        // approximations:
        case CPRoundRectBezelStyle:
            positionOffsetOriginY = -3;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPRoundedBezelStyle;
            break;

        case CPSmallSquareBezelStyle:
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            break;

        case CPThickSquareBezelStyle:
        case CPThickerSquareBezelStyle:
        case CPRegularSquareBezelStyle:
            positionOffsetOriginY = 3;
            positionOffsetOriginX = 0;
            positionOffsetSizeWidth = -4;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            break;

        case CPTexturedSquareBezelStyle:
            positionOffsetOriginY = 4;
            positionOffsetOriginX = -1;
            positionOffsetSizeWidth = -2;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            break;

        case CPShadowlessSquareBezelStyle:
            positionOffsetOriginY = 5;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            break;

        case CPRecessedBezelStyle:
            positionOffsetOriginY = -3;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPHUDBezelStyle;
            break;

        // unsupported
        case CPRoundedDisclosureBezelStyle:
        case CPHelpButtonBezelStyle:
        case CPCircularBezelStyle:
        case CPDisclosureBezelStyle:
            CPLog.warn("NSButton [%s]: unsupported bezel style: %d", _title == null ? "<no title>" : '"' + _title + '"', _bezelStyle);
            _bezelStyle = CPHUDBezelStyle;
            break;

        // error:
        default:
            CPLog.warn("NSButton [%s]: unknown bezel style: %d", _title == null ? "<no title>" : '"' + _title + '"', _bezelStyle);
            _bezelStyle = CPHUDBezelStyle;
    }

    if ([cell isBordered])
    {
        CPLog.debug("NSButton [%s]: adjusting height from %d to %d", _title == null ? "<no title>" : '"' + _title + '"', _frame.size.height, CPButtonDefaultHeight);
        _frame.size.height = CPButtonDefaultHeight;

        // Reposition the buttons according to its particular offsets
        _frame.origin.x += positionOffsetOriginX;
        _frame.origin.y += positionOffsetOriginY;
        _frame.size.width += positionOffsetSizeWidth;
        _bounds.size.width += positionOffsetSizeWidth;

        _bounds.size.height = CPButtonDefaultHeight;
    }

    _keyEquivalent = [cell keyEquivalent];
    _keyEquivalentModifierMask = [cell keyEquivalentModifierMask];
    _imageDimsWhenDisabled = YES;

    _allowsMixedState = [cell allowsMixedState];
    [self setImage:[cell normalImage]];
    [self setAlternateImage:alternateImage];
    [self setImagePosition:[cell imagePosition]];

    [self setEnabled:[cell isEnabled]];

    _highlightsBy = [cell highlightsBy];
    _showsStateBy = [cell showsStateBy];

    return self;
}

@end

@implementation NSButton : CPButton

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPButton class];
}

@end

@implementation NSButtonCell : NSActionCell
{
    BOOL        _isBordered         @accessors(readonly, getter=isBordered);
    int         _bezelStyle         @accessors(readonly, getter=bezelStyle);

    CPString    _title              @accessors(readonly, getter=title);
    CPString    _alternateTitle     @accessors(readonly, getter=alternateTitle);
    CPImage     _normalImage        @accessors(readonly, getter=normalImage);
    CPImage     _alternateImage     @accessors(readonly, getter=alternateImage);

    BOOL        _allowsMixedState   @accessors(readonly, getter=allowsMixedState);
    BOOL        _imagePosition      @accessors(readonly, getter=imagePosition);

    int         _highlightsBy       @accessors(readonly, getter=highlightsBy);
    int         _showsStateBy       @accessors(readonly, getter=showsStateBy);

    CPString    _keyEquivalent      @accessors(readonly, getter=keyEquivalent);
    unsigned    _keyEquivalentModifierMask @accessors(readonly, getter=keyEquivalentModifierMask);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        var buttonFlags = [aCoder decodeIntForKey:@"NSButtonFlags"],
            buttonFlags2 = [aCoder decodeIntForKey:@"NSButtonFlags2"],
            cellFlags2 = [aCoder decodeIntForKey:@"NSCellFlags2"],
            position = (buttonFlags & NSButtonImagePositionMask) >> NSButtonImagePositionShift;

        _isBordered = (buttonFlags & NSButtonIsBorderedMask) ? YES : NO;
        _bezelStyle = (buttonFlags2 & 0x7) | ((buttonFlags2 & 0x20) >> 2);

        // NSContents/NSAlternateContents for NSButton is actually the title/alternate title
        _title = [aCoder decodeObjectForKey:@"NSContents"];
        _alternateTitle = [aCoder decodeObjectForKey:@"NSAlternateContents"];
        // ... and _objectValue is _state
        _objectValue = [self state];

        _normalImage = [aCoder decodeObjectForKey:@"NSNormalImage"];
        _alternateImage = [aCoder decodeObjectForKey:@"NSAlternateImage"];
        _allowsMixedState = (cellFlags2 & NSButtonAllowsMixedStateMask) ? YES : NO;

        // Test in decreasing order of mask value to ensure the correct match,
        // because some of the positions don't care about some bits.

        if ((position & NSButtonImageOverlapsPositionMask) == NSButtonImageOverlapsPositionMask)
            _imagePosition = CPImageOverlaps;
        else if ((position & NSButtonImageOnlyPositionMask) == NSButtonImageOnlyPositionMask)
            _imagePosition = CPImageOnly;
        else if ((position & NSButtonImageLeftPositionMask) == NSButtonImageLeftPositionMask)
            _imagePosition = CPImageLeft;
        else if ((position & NSButtonImageRightPositionMask) == NSButtonImageRightPositionMask)
            _imagePosition = CPImageRight;
        else if ((position & NSButtonImageBelowPositionMask) == NSButtonImageBelowPositionMask)
            _imagePosition = CPImageBelow;
        else if ((position & NSButtonImageAbovePositionMask) == NSButtonImageAbovePositionMask)
            _imagePosition = CPImageAbove;
        else if ((position & NSButtonNoImagePositionMask) == NSButtonNoImagePositionMask)
            _imagePosition = CPNoImage;

        _highlightsBy = CPNoCellMask;

        if (buttonFlags & NSHighlightsByPushInCellMask)
            _highlightsBy |= CPPushInCellMask;
        if (buttonFlags & NSHighlightsByContentsCellMask)
            _highlightsBy |= CPContentsCellMask;
        if (buttonFlags & NSHighlightsByChangeGrayCellMask)
            _highlightsBy |= CPChangeGrayCellMask;
        if (buttonFlags & NSHighlightsByChangeBackgroundCellMask)
            _highlightsBy |= CPChangeBackgroundCellMask;

        _showsStateBy = CPNoCellMask;

        if (buttonFlags & NSShowsStateByContentsCellMask)
            _showsStateBy |= CPContentsCellMask;
        if (buttonFlags & NSShowsStateByChangeGrayCellMask)
            _showsStateBy |= CPChangeGrayCellMask;
        if (buttonFlags & NSShowsStateByChangeBackgroundCellMask)
            _showsStateBy |= CPChangeBackgroundCellMask;

        _keyEquivalent = [aCoder decodeObjectForKey:@"NSKeyEquivalent"];
        _keyEquivalentModifierMask = buttonFlags2 >> 8;
    }

    return self;
}

@end

@implementation NSButtonImageSource : CPObject
{
    CPString _imageName @accessors(readonly, getter=imageName);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _imageName = [aCoder decodeObjectForKey:@"NSImageName"];

    return self;
}

@end
