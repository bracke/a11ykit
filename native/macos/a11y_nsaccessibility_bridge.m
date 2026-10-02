/*
 * Minimal NSAccessibility ABI bridge.
 *
 * This file intentionally contains no accessibility semantics. Role mapping,
 * attribute/action selection, exposure policy, event coalescing, and provider
 * dispatch live in Ada backend-private packages.
 */

#import <Foundation/Foundation.h>
#if defined(__APPLE__) && defined(__MACH__)
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#endif
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>

#define A11Y_NSAX_MAX_UTF8_BYTES 65536u
#define A11Y_NSAX_MAX_ARRAY_COUNT 4096u

typedef int (*a11y_nsax_callback)(unsigned long long session,
                                  unsigned long long node,
                                  unsigned int selector,
                                  unsigned int operand,
                                  void *context);

typedef int (*a11y_nsax_value_callback)(unsigned long long session,
                                        unsigned long long node,
                                        unsigned int selector,
                                        unsigned int operand,
                                        unsigned int *value_kind,
                                        unsigned int *items,
                                        unsigned long long item_capacity,
                                        unsigned long long *item_count,
                                        char *utf8,
                                        unsigned long long utf8_capacity,
                                        unsigned long long *utf8_used,
                                        void *context);

typedef int (*a11y_nsax_object_callback)(unsigned long long session,
                                         unsigned long long node,
                                         unsigned int selector,
                                         unsigned int operand,
                                         long long point_x,
                                         long long point_y,
                                         unsigned long long *items,
                                         unsigned long long item_capacity,
                                         unsigned long long *item_count,
                                         void *context);

enum {
    A11Y_NSAX_SELECTOR_ATTRIBUTE_NAMES = 1u,
    A11Y_NSAX_SELECTOR_ATTRIBUTE_VALUE = 2u,
    A11Y_NSAX_SELECTOR_IS_ATTRIBUTE_SETTABLE = 3u,
    A11Y_NSAX_SELECTOR_SET_VALUE = 4u,
    A11Y_NSAX_SELECTOR_ACTION_NAMES = 5u,
    A11Y_NSAX_SELECTOR_PERFORM_ACTION = 6u,
    A11Y_NSAX_SELECTOR_PARENT = 7u,
    A11Y_NSAX_SELECTOR_CHILDREN = 8u,
    A11Y_NSAX_SELECTOR_CHILD_AT_INDEX = 9u,
    A11Y_NSAX_SELECTOR_HIT_TEST = 10u,
    A11Y_NSAX_SELECTOR_FOCUSED_UI_ELEMENT = 11u,
    A11Y_NSAX_SELECTOR_POST_NOTIFICATION = 12u
};

enum {
    A11Y_NSAX_VALUE_NONE = 0u,
    A11Y_NSAX_VALUE_ATTRIBUTE_ARRAY = 1u,
    A11Y_NSAX_VALUE_ACTION_ARRAY = 2u,
    A11Y_NSAX_VALUE_UTF8_STRING = 3u,
    A11Y_NSAX_VALUE_BOOLEAN = 4u,
    A11Y_NSAX_VALUE_INTEGER = 5u,
    A11Y_NSAX_VALUE_ROLE = 6u,
    A11Y_NSAX_VALUE_RECTANGLE = 7u
};

enum {
    A11Y_NSAX_ATTRIBUTE_ROLE = 1u,
    A11Y_NSAX_ATTRIBUTE_TITLE = 2u,
    A11Y_NSAX_ATTRIBUTE_LABEL = 3u,
    A11Y_NSAX_ATTRIBUTE_DESCRIPTION = 4u,
    A11Y_NSAX_ATTRIBUTE_HELP = 5u,
    A11Y_NSAX_ATTRIBUTE_PLACEHOLDER = 6u,
    A11Y_NSAX_ATTRIBUTE_VALUE_TEXT = 7u,
    A11Y_NSAX_ATTRIBUTE_KEYBOARD_SHORTCUT = 8u,
    A11Y_NSAX_ATTRIBUTE_LOCALE = 9u,
    A11Y_NSAX_ATTRIBUTE_ORIENTATION = 10u,
    A11Y_NSAX_ATTRIBUTE_POSITION_IN_SET = 11u,
    A11Y_NSAX_ATTRIBUTE_SIZE_OF_SET = 12u,
    A11Y_NSAX_ATTRIBUTE_HIERARCHICAL_LEVEL = 13u,
    A11Y_NSAX_ATTRIBUTE_HEADING_LEVEL = 14u,
    A11Y_NSAX_ATTRIBUTE_LANDMARK = 15u,
    A11Y_NSAX_ATTRIBUTE_IDENTIFIER = 16u,
    A11Y_NSAX_ATTRIBUTE_FRAME = 17u,
    A11Y_NSAX_ATTRIBUTE_ENABLED = 18u,
    A11Y_NSAX_ATTRIBUTE_FOCUSED = 19u,
    A11Y_NSAX_ATTRIBUTE_SELECTED = 20u,
    A11Y_NSAX_ATTRIBUTE_REQUIRED = 21u,
    A11Y_NSAX_ATTRIBUTE_MODAL = 22u,
    A11Y_NSAX_RELATION_LABELLED_BY = 1001u,
    A11Y_NSAX_RELATION_LABEL_FOR = 1002u,
    A11Y_NSAX_RELATION_CONTROLLED_BY = 1003u,
    A11Y_NSAX_RELATION_CONTROLLER_FOR = 1004u,
    A11Y_NSAX_RELATION_FLOWS_TO = 1005u,
    A11Y_NSAX_RELATION_FLOWS_FROM = 1006u,
    A11Y_NSAX_RELATION_MEMBER_OF = 1007u,
    A11Y_NSAX_RELATION_DETAILS = 1008u,
    A11Y_NSAX_RELATION_DETAILS_FOR = 1009u,
    A11Y_NSAX_RELATION_ERROR_MESSAGE = 1010u,
    A11Y_NSAX_RELATION_ERROR_FOR = 1011u,
    A11Y_NSAX_RELATION_ACTIVE_DESCENDANT = 1012u,
    A11Y_NSAX_RELATION_POPUP_FOR = 1013u,
    A11Y_NSAX_RELATION_POPUP_CONTROLLED_BY = 1014u
};

enum {
    A11Y_NSAX_ACTION_ACTIVATE = 1u,
    A11Y_NSAX_ACTION_PRESS = 2u,
    A11Y_NSAX_ACTION_TOGGLE = 3u,
    A11Y_NSAX_ACTION_EXPAND = 4u,
    A11Y_NSAX_ACTION_COLLAPSE = 5u,
    A11Y_NSAX_ACTION_SHOW_MENU = 6u,
    A11Y_NSAX_ACTION_DISMISS = 7u,
    A11Y_NSAX_ACTION_INCREMENT = 8u,
    A11Y_NSAX_ACTION_DECREMENT = 9u,
    A11Y_NSAX_ACTION_SELECT_ITEM = 10u,
    A11Y_NSAX_ACTION_DESELECT = 11u,
    A11Y_NSAX_ACTION_CLEAR_SELECTION = 12u,
    A11Y_NSAX_ACTION_SCROLL_INTO_VIEW = 13u,
    A11Y_NSAX_ACTION_SET_FOCUS = 14u,
    A11Y_NSAX_ACTION_OPEN = 15u,
    A11Y_NSAX_ACTION_CLOSE = 16u
};

enum {
    A11Y_NSAX_NOTIFICATION_FOCUSED_UI_ELEMENT_CHANGED = 1u,
    A11Y_NSAX_NOTIFICATION_TITLE_CHANGED = 2u,
    A11Y_NSAX_NOTIFICATION_VALUE_CHANGED = 3u,
    A11Y_NSAX_NOTIFICATION_SELECTED_CHILDREN_CHANGED = 4u,
    A11Y_NSAX_NOTIFICATION_SELECTED_TEXT_CHANGED = 5u,
    A11Y_NSAX_NOTIFICATION_ROW_COUNT_CHANGED = 6u,
    A11Y_NSAX_NOTIFICATION_LAYOUT_CHANGED = 7u,
    A11Y_NSAX_NOTIFICATION_UI_ELEMENT_DESTROYED = 8u,
    A11Y_NSAX_NOTIFICATION_WINDOW_CREATED = 9u,
    A11Y_NSAX_NOTIFICATION_WINDOW_MOVED = 10u,
    A11Y_NSAX_NOTIFICATION_WINDOW_RESIZED = 11u,
    A11Y_NSAX_NOTIFICATION_MAIN_WINDOW_CHANGED = 12u,
    A11Y_NSAX_NOTIFICATION_ANNOUNCEMENT_REQUESTED = 13u,
    A11Y_NSAX_NOTIFICATION_LIVE_REGION_CHANGED = 14u
};

enum {
    A11Y_NSAX_PROBE_ELEMENT_CREATED = 1u << 0,
    A11Y_NSAX_PROBE_IDENTITY_MATCHED = 1u << 1,
    A11Y_NSAX_PROBE_ATTRIBUTE_NAMES_DISPATCHED = 1u << 2,
    A11Y_NSAX_PROBE_ATTRIBUTE_VALUE_DISPATCHED = 1u << 3,
    A11Y_NSAX_PROBE_SETTABLE_DISPATCHED = 1u << 4,
    A11Y_NSAX_PROBE_ACTION_NAMES_DISPATCHED = 1u << 5,
    A11Y_NSAX_PROBE_PARENT_DISPATCHED = 1u << 6,
    A11Y_NSAX_PROBE_CHILDREN_DISPATCHED = 1u << 7,
    A11Y_NSAX_PROBE_CHILD_AT_INDEX_DISPATCHED = 1u << 8,
    A11Y_NSAX_PROBE_HIT_TEST_DISPATCHED = 1u << 9,
    A11Y_NSAX_PROBE_FOCUSED_DISPATCHED = 1u << 10,
    A11Y_NSAX_PROBE_NOTIFICATION_DISPATCHED = 1u << 11,
    A11Y_NSAX_PROBE_RELEASED = 1u << 12
};

enum {
    A11Y_NSAX_PUBLIC_AX_PROBE_TRUST_CHECKED = 1u << 0,
    A11Y_NSAX_PUBLIC_AX_PROBE_APPLICATION_CREATED = 1u << 1,
    A11Y_NSAX_PUBLIC_AX_PROBE_ATTRIBUTE_NAMES_ATTEMPTED = 1u << 2,
    A11Y_NSAX_PUBLIC_AX_PROBE_ROLE_ATTEMPTED = 1u << 3,
    A11Y_NSAX_PUBLIC_AX_PROBE_WINDOWS_ATTEMPTED = 1u << 4,
    A11Y_NSAX_PUBLIC_AX_PROBE_WINDOW_CHILDREN_ATTEMPTED = 1u << 5,
    A11Y_NSAX_PUBLIC_AX_PROBE_ROOT_ROLE_ATTEMPTED = 1u << 6,
    A11Y_NSAX_PUBLIC_AX_PROBE_RELEASED = 1u << 7
};

#if defined(__APPLE__) && defined(__MACH__)
static unsigned int a11y_nsax_positive_index_operand(NSInteger index) {
    if (index < 0 || (unsigned long long)index >= UINT_MAX) {
        return 0u;
    }
    return (unsigned int)index + 1u;
}

static NSString *a11y_nsax_attribute_name(unsigned int attribute) {
    switch (attribute) {
        case A11Y_NSAX_ATTRIBUTE_ROLE:
            return @"AXRole";
        case A11Y_NSAX_ATTRIBUTE_TITLE:
            return @"AXTitle";
        case A11Y_NSAX_ATTRIBUTE_LABEL:
            return @"AXLabel";
        case A11Y_NSAX_ATTRIBUTE_DESCRIPTION:
            return @"AXDescription";
        case A11Y_NSAX_ATTRIBUTE_HELP:
            return @"AXHelp";
        case A11Y_NSAX_ATTRIBUTE_PLACEHOLDER:
            return @"AXPlaceholderValue";
        case A11Y_NSAX_ATTRIBUTE_VALUE_TEXT:
            return @"AXValue";
        case A11Y_NSAX_ATTRIBUTE_KEYBOARD_SHORTCUT:
            return @"AXMenuItemCmdChar";
        case A11Y_NSAX_ATTRIBUTE_LOCALE:
            return @"AXLanguage";
        case A11Y_NSAX_ATTRIBUTE_ORIENTATION:
            return @"AXOrientation";
        case A11Y_NSAX_ATTRIBUTE_POSITION_IN_SET:
            return @"AXARIAPosInSet";
        case A11Y_NSAX_ATTRIBUTE_SIZE_OF_SET:
            return @"AXARIASetSize";
        case A11Y_NSAX_ATTRIBUTE_HIERARCHICAL_LEVEL:
            return @"AXDisclosureLevel";
        case A11Y_NSAX_ATTRIBUTE_HEADING_LEVEL:
            return @"AXHeadingLevel";
        case A11Y_NSAX_ATTRIBUTE_LANDMARK:
            return @"AXLandmarkType";
        case A11Y_NSAX_ATTRIBUTE_IDENTIFIER:
            return @"AXIdentifier";
        case A11Y_NSAX_ATTRIBUTE_FRAME:
            return @"AXFrame";
        case A11Y_NSAX_ATTRIBUTE_ENABLED:
            return @"AXEnabled";
        case A11Y_NSAX_ATTRIBUTE_FOCUSED:
            return @"AXFocused";
        case A11Y_NSAX_ATTRIBUTE_SELECTED:
            return @"AXSelected";
        case A11Y_NSAX_ATTRIBUTE_REQUIRED:
            return @"AXRequired";
        case A11Y_NSAX_ATTRIBUTE_MODAL:
            return @"AXModal";
        case A11Y_NSAX_RELATION_LABELLED_BY:
            return @"AXTitleUIElement";
        case A11Y_NSAX_RELATION_LABEL_FOR:
            return @"AXServesAsTitleForUIElements";
        case A11Y_NSAX_RELATION_CONTROLLED_BY:
        case A11Y_NSAX_RELATION_CONTROLLER_FOR:
        case A11Y_NSAX_RELATION_FLOWS_TO:
        case A11Y_NSAX_RELATION_FLOWS_FROM:
        case A11Y_NSAX_RELATION_POPUP_FOR:
        case A11Y_NSAX_RELATION_POPUP_CONTROLLED_BY:
            return @"AXLinkedUIElements";
        case A11Y_NSAX_RELATION_MEMBER_OF:
            return @"AXSharedFocusElements";
        case A11Y_NSAX_RELATION_DETAILS:
        case A11Y_NSAX_RELATION_DETAILS_FOR:
            return @"AXDetailsElements";
        case A11Y_NSAX_RELATION_ERROR_MESSAGE:
        case A11Y_NSAX_RELATION_ERROR_FOR:
            return @"AXErrorMessageElements";
        case A11Y_NSAX_RELATION_ACTIVE_DESCENDANT:
            return @"AXActiveDescendant";
        default:
            return nil;
    }
}

static unsigned int a11y_nsax_attribute_operand(NSString *attribute) {
    if (attribute == nil) {
        return 0u;
    }
    if ([attribute isEqualToString:@"AXRole"]) {
        return A11Y_NSAX_ATTRIBUTE_ROLE;
    }
    if ([attribute isEqualToString:@"AXTitle"]) {
        return A11Y_NSAX_ATTRIBUTE_TITLE;
    }
    if ([attribute isEqualToString:@"AXLabel"]) {
        return A11Y_NSAX_ATTRIBUTE_LABEL;
    }
    if ([attribute isEqualToString:@"AXDescription"]) {
        return A11Y_NSAX_ATTRIBUTE_DESCRIPTION;
    }
    if ([attribute isEqualToString:@"AXHelp"]) {
        return A11Y_NSAX_ATTRIBUTE_HELP;
    }
    if ([attribute isEqualToString:@"AXPlaceholderValue"]) {
        return A11Y_NSAX_ATTRIBUTE_PLACEHOLDER;
    }
    if ([attribute isEqualToString:@"AXValue"]) {
        return A11Y_NSAX_ATTRIBUTE_VALUE_TEXT;
    }
    if ([attribute isEqualToString:@"AXMenuItemCmdChar"] ||
        [attribute isEqualToString:@"AXAccessKey"]) {
        return A11Y_NSAX_ATTRIBUTE_KEYBOARD_SHORTCUT;
    }
    if ([attribute isEqualToString:@"AXLanguage"] ||
        [attribute isEqualToString:@"AXLocale"]) {
        return A11Y_NSAX_ATTRIBUTE_LOCALE;
    }
    if ([attribute isEqualToString:@"AXOrientation"]) {
        return A11Y_NSAX_ATTRIBUTE_ORIENTATION;
    }
    if ([attribute isEqualToString:@"AXARIAPosInSet"]) {
        return A11Y_NSAX_ATTRIBUTE_POSITION_IN_SET;
    }
    if ([attribute isEqualToString:@"AXARIASetSize"]) {
        return A11Y_NSAX_ATTRIBUTE_SIZE_OF_SET;
    }
    if ([attribute isEqualToString:@"AXDisclosureLevel"]) {
        return A11Y_NSAX_ATTRIBUTE_HIERARCHICAL_LEVEL;
    }
    if ([attribute isEqualToString:@"AXHeadingLevel"]) {
        return A11Y_NSAX_ATTRIBUTE_HEADING_LEVEL;
    }
    if ([attribute isEqualToString:@"AXLandmarkType"]) {
        return A11Y_NSAX_ATTRIBUTE_LANDMARK;
    }
    if ([attribute isEqualToString:@"AXIdentifier"]) {
        return A11Y_NSAX_ATTRIBUTE_IDENTIFIER;
    }
    if ([attribute isEqualToString:@"AXFrame"]) {
        return A11Y_NSAX_ATTRIBUTE_FRAME;
    }
    if ([attribute isEqualToString:@"AXEnabled"]) {
        return A11Y_NSAX_ATTRIBUTE_ENABLED;
    }
    if ([attribute isEqualToString:@"AXFocused"]) {
        return A11Y_NSAX_ATTRIBUTE_FOCUSED;
    }
    if ([attribute isEqualToString:@"AXSelected"]) {
        return A11Y_NSAX_ATTRIBUTE_SELECTED;
    }
    if ([attribute isEqualToString:@"AXRequired"]) {
        return A11Y_NSAX_ATTRIBUTE_REQUIRED;
    }
    if ([attribute isEqualToString:@"AXModal"]) {
        return A11Y_NSAX_ATTRIBUTE_MODAL;
    }
    if ([attribute isEqualToString:@"AXTitleUIElement"]) {
        return A11Y_NSAX_RELATION_LABELLED_BY;
    }
    if ([attribute isEqualToString:@"AXServesAsTitleForUIElements"]) {
        return A11Y_NSAX_RELATION_LABEL_FOR;
    }
    if ([attribute isEqualToString:@"AXLinkedUIElements"]) {
        return A11Y_NSAX_RELATION_CONTROLLED_BY;
    }
    if ([attribute isEqualToString:@"AXSharedFocusElements"]) {
        return A11Y_NSAX_RELATION_MEMBER_OF;
    }
    if ([attribute isEqualToString:@"AXDetailsElements"]) {
        return A11Y_NSAX_RELATION_DETAILS;
    }
    if ([attribute isEqualToString:@"AXErrorMessageElements"]) {
        return A11Y_NSAX_RELATION_ERROR_MESSAGE;
    }
    if ([attribute isEqualToString:@"AXActiveDescendant"]) {
        return A11Y_NSAX_RELATION_ACTIVE_DESCENDANT;
    }
    return 0u;
}

static NSString *a11y_nsax_action_name(unsigned int action) {
    switch (action) {
        case A11Y_NSAX_ACTION_PRESS:
        case A11Y_NSAX_ACTION_ACTIVATE:
        case A11Y_NSAX_ACTION_TOGGLE:
            return @"AXPress";
        case A11Y_NSAX_ACTION_EXPAND:
            return @"AXExpand";
        case A11Y_NSAX_ACTION_COLLAPSE:
            return @"AXCollapse";
        case A11Y_NSAX_ACTION_SHOW_MENU:
            return @"AXShowMenu";
        case A11Y_NSAX_ACTION_DISMISS:
            return @"AXCancel";
        case A11Y_NSAX_ACTION_INCREMENT:
            return @"AXIncrement";
        case A11Y_NSAX_ACTION_DECREMENT:
            return @"AXDecrement";
        case A11Y_NSAX_ACTION_SELECT_ITEM:
            return @"AXPick";
        case A11Y_NSAX_ACTION_SCROLL_INTO_VIEW:
            return @"AXScrollToVisible";
        case A11Y_NSAX_ACTION_SET_FOCUS:
            return @"AXRaise";
        case A11Y_NSAX_ACTION_OPEN:
            return @"AXConfirm";
        case A11Y_NSAX_ACTION_CLOSE:
            return @"AXClose";
        default:
            return nil;
    }
}

static unsigned int a11y_nsax_action_operand(NSString *action) {
    if (action == nil) {
        return 0u;
    }
    if ([action isEqualToString:@"AXPress"]) {
        return A11Y_NSAX_ACTION_PRESS;
    }
    if ([action isEqualToString:@"AXExpand"]) {
        return A11Y_NSAX_ACTION_EXPAND;
    }
    if ([action isEqualToString:@"AXCollapse"]) {
        return A11Y_NSAX_ACTION_COLLAPSE;
    }
    if ([action isEqualToString:@"AXShowMenu"]) {
        return A11Y_NSAX_ACTION_SHOW_MENU;
    }
    if ([action isEqualToString:@"AXCancel"]) {
        return A11Y_NSAX_ACTION_DISMISS;
    }
    if ([action isEqualToString:@"AXIncrement"]) {
        return A11Y_NSAX_ACTION_INCREMENT;
    }
    if ([action isEqualToString:@"AXDecrement"]) {
        return A11Y_NSAX_ACTION_DECREMENT;
    }
    if ([action isEqualToString:@"AXPick"]) {
        return A11Y_NSAX_ACTION_SELECT_ITEM;
    }
    if ([action isEqualToString:@"AXScrollToVisible"]) {
        return A11Y_NSAX_ACTION_SCROLL_INTO_VIEW;
    }
    if ([action isEqualToString:@"AXRaise"]) {
        return A11Y_NSAX_ACTION_SET_FOCUS;
    }
    if ([action isEqualToString:@"AXConfirm"]) {
        return A11Y_NSAX_ACTION_OPEN;
    }
    if ([action isEqualToString:@"AXClose"]) {
        return A11Y_NSAX_ACTION_CLOSE;
    }
    return 0u;
}

static NSString *a11y_nsax_notification_name(unsigned int notification) {
    switch (notification) {
        case A11Y_NSAX_NOTIFICATION_FOCUSED_UI_ELEMENT_CHANGED:
            return @"AXFocusedUIElementChanged";
        case A11Y_NSAX_NOTIFICATION_TITLE_CHANGED:
            return @"AXTitleChanged";
        case A11Y_NSAX_NOTIFICATION_VALUE_CHANGED:
            return @"AXValueChanged";
        case A11Y_NSAX_NOTIFICATION_SELECTED_CHILDREN_CHANGED:
            return @"AXSelectedChildrenChanged";
        case A11Y_NSAX_NOTIFICATION_SELECTED_TEXT_CHANGED:
            return @"AXSelectedTextChanged";
        case A11Y_NSAX_NOTIFICATION_ROW_COUNT_CHANGED:
            return @"AXRowCountChanged";
        case A11Y_NSAX_NOTIFICATION_LAYOUT_CHANGED:
            return @"AXLayoutChanged";
        case A11Y_NSAX_NOTIFICATION_UI_ELEMENT_DESTROYED:
            return @"AXUIElementDestroyed";
        case A11Y_NSAX_NOTIFICATION_WINDOW_CREATED:
            return @"AXWindowCreated";
        case A11Y_NSAX_NOTIFICATION_WINDOW_MOVED:
            return @"AXWindowMoved";
        case A11Y_NSAX_NOTIFICATION_WINDOW_RESIZED:
            return @"AXWindowResized";
        case A11Y_NSAX_NOTIFICATION_MAIN_WINDOW_CHANGED:
            return @"AXMainWindowChanged";
        case A11Y_NSAX_NOTIFICATION_ANNOUNCEMENT_REQUESTED:
            return @"AXAnnouncementRequested";
        case A11Y_NSAX_NOTIFICATION_LIVE_REGION_CHANGED:
            return @"AXLiveRegionChanged";
        default:
            return nil;
    }
}

static unsigned int a11y_nsax_notification_operand(NSString *notification) {
    if (notification == nil) {
        return 0u;
    }

    for (unsigned int code = A11Y_NSAX_NOTIFICATION_FOCUSED_UI_ELEMENT_CHANGED;
         code <= A11Y_NSAX_NOTIFICATION_LIVE_REGION_CHANGED;
         code++) {
        NSString *name = a11y_nsax_notification_name(code);
        if (name != nil && [notification isEqualToString:name]) {
            return code;
        }
    }

    return 0u;
}

static NSString *a11y_nsax_role_name(unsigned int role) {
    switch (role) {
        case 1u:
            return @"AXApplication";
        case 2u:
            return @"AXWindow";
        case 3u:
            return @"AXDialog";
        case 4u:
            return @"AXGroup";
        case 5u:
            return @"AXButton";
        case 6u:
            return @"AXCheckBox";
        case 7u:
            return @"AXRadioButton";
        case 8u:
            return @"AXComboBox";
        case 9u:
            return @"AXList";
        case 10u:
            return @"AXRow";
        case 11u:
            return @"AXOutline";
        case 12u:
            return @"AXTable";
        case 13u:
            return @"AXCell";
        case 14u:
            return @"AXTabGroup";
        case 15u:
            return @"AXMenuBar";
        case 16u:
            return @"AXMenu";
        case 17u:
            return @"AXMenuItem";
        case 18u:
            return @"AXToolbar";
        case 19u:
            return @"AXStaticText";
        case 20u:
            return @"AXTextField";
        case 21u:
            return @"AXSecureTextField";
        case 22u:
            return @"AXSlider";
        case 23u:
            return @"AXIncrementor";
        case 24u:
            return @"AXProgressIndicator";
        case 25u:
            return @"AXScrollBar";
        case 26u:
            return @"AXLink";
        case 27u:
            return @"AXImage";
        case 28u:
            return @"AXHeading";
        case 29u:
            return @"AXSplitter";
        case 30u:
            return @"AXValueIndicator";
        case 31u:
            return @"AXHelpTag";
        case 32u:
            return @"AXDocument";
        default:
            return @"AXUnknown";
    }
}

static int32_t a11y_nsax_decode_i32(unsigned int value) {
    return (int32_t)(uint32_t)value;
}

@interface A11yNSAXElement : NSAccessibilityElement {
@private
    unsigned long long a11y_session;
    unsigned long long a11y_node;
    a11y_nsax_callback a11y_callback;
    a11y_nsax_value_callback a11y_value_callback;
    a11y_nsax_object_callback a11y_object_callback;
    void *a11y_context;
}
- (id)initWithSession:(unsigned long long)session
                 node:(unsigned long long)node
             callback:(a11y_nsax_callback)callback
        valueCallback:(a11y_nsax_value_callback)valueCallback
       objectCallback:(a11y_nsax_object_callback)objectCallback
              context:(void *)context;
- (int)a11yDispatchSelector:(unsigned int)selector;
- (int)a11yDispatchSelector:(unsigned int)selector
                    operand:(unsigned int)operand;
- (id)a11yCopyValueForSelector:(unsigned int)selector
                       operand:(unsigned int)operand;
- (id)a11yCreateElementForNode:(unsigned long long)node;
- (NSArray *)a11yCopyObjectsForSelector:(unsigned int)selector
                                operand:(unsigned int)operand;
- (NSArray *)a11yCopyObjectsForSelector:(unsigned int)selector
                                operand:(unsigned int)operand
                                  pointX:(long long)pointX
                                  pointY:(long long)pointY;
- (unsigned long long)a11ySession;
- (unsigned long long)a11yNode;
@end

@interface A11yNSAXHostView : NSView {
@private
    A11yNSAXElement *a11y_root;
}
- (id)initWithFrame:(NSRect)frame root:(A11yNSAXElement *)root;
@end

@interface A11yNSAXProcessRootHost : NSObject {
@private
    NSWindow *a11y_window;
    A11yNSAXHostView *a11y_view;
    A11yNSAXElement *a11y_root;
}
- (id)initWithRoot:(A11yNSAXElement *)root;
- (int)a11yPostNotificationCode:(unsigned int)notification;
@end

@implementation A11yNSAXElement
- (id)initWithSession:(unsigned long long)session
                 node:(unsigned long long)node
             callback:(a11y_nsax_callback)callback
        valueCallback:(a11y_nsax_value_callback)valueCallback
       objectCallback:(a11y_nsax_object_callback)objectCallback
              context:(void *)context {
    self = [super init];
    if (self != nil) {
        a11y_session = session;
        a11y_node = node;
        a11y_callback = callback;
        a11y_value_callback = valueCallback;
        a11y_object_callback = objectCallback;
        a11y_context = context;
    }
    return self;
}

- (int)a11yDispatchSelector:(unsigned int)selector {
    return [self a11yDispatchSelector:selector operand:0u];
}

- (int)a11yDispatchSelector:(unsigned int)selector
                    operand:(unsigned int)operand {
    if (a11y_callback == 0) {
        return 0;
    }
    return a11y_callback(a11y_session,
                         a11y_node,
                         selector,
                         operand,
                         a11y_context);
}

- (id)a11yCopyValueForSelector:(unsigned int)selector
                       operand:(unsigned int)operand {
    unsigned int value_kind = A11Y_NSAX_VALUE_NONE;
    unsigned int items[128];
    unsigned long long item_count = 0;
    char utf8[A11Y_NSAX_MAX_UTF8_BYTES + 1u];
    unsigned long long utf8_used = 0;

    if (a11y_value_callback == 0) {
        return nil;
    }

    memset(items, 0, sizeof(items));
    memset(utf8, 0, sizeof(utf8));

    if (a11y_value_callback(a11y_session,
                            a11y_node,
                            selector,
                            operand,
                            &value_kind,
                            items,
                            128u,
                            &item_count,
                            utf8,
                            A11Y_NSAX_MAX_UTF8_BYTES,
                            &utf8_used,
                            a11y_context) == 0) {
        return nil;
    }

    if (item_count > 128u || utf8_used > A11Y_NSAX_MAX_UTF8_BYTES) {
        return nil;
    }

    switch (value_kind) {
        case A11Y_NSAX_VALUE_ATTRIBUTE_ARRAY: {
            NSMutableArray *array =
                [[NSMutableArray alloc] initWithCapacity:(NSUInteger)item_count];
            for (unsigned long long index = 0; index < item_count; ++index) {
                NSString *name = a11y_nsax_attribute_name(items[index]);
                if (name != nil) {
                    [array addObject:name];
                }
            }
            return [array autorelease];
        }
        case A11Y_NSAX_VALUE_ACTION_ARRAY: {
            NSMutableArray *array =
                [[NSMutableArray alloc] initWithCapacity:(NSUInteger)item_count];
            for (unsigned long long index = 0; index < item_count; ++index) {
                NSString *name = a11y_nsax_action_name(items[index]);
                if (name != nil) {
                    [array addObject:name];
                }
            }
            return [array autorelease];
        }
        case A11Y_NSAX_VALUE_UTF8_STRING:
            return [[[NSString alloc] initWithBytes:utf8
                                             length:(NSUInteger)utf8_used
                                           encoding:NSUTF8StringEncoding]
                    autorelease];
        case A11Y_NSAX_VALUE_BOOLEAN:
            return [NSNumber numberWithBool:(utf8_used != 0u)];
        case A11Y_NSAX_VALUE_INTEGER:
            return [NSNumber numberWithLongLong:(long long)utf8_used];
        case A11Y_NSAX_VALUE_ROLE:
            return a11y_nsax_role_name((unsigned int)utf8_used);
        case A11Y_NSAX_VALUE_RECTANGLE:
            if (item_count < 4u) {
                return nil;
            }
            return [NSValue valueWithRect:
                NSMakeRect((CGFloat)a11y_nsax_decode_i32(items[0]),
                           (CGFloat)a11y_nsax_decode_i32(items[1]),
                           (CGFloat)a11y_nsax_decode_i32(items[2]),
                           (CGFloat)a11y_nsax_decode_i32(items[3]))];
        default:
            return nil;
    }
}

- (id)a11yCreateElementForNode:(unsigned long long)node {
    if (node == 0u || a11y_callback == 0) {
        return nil;
    }

    return [[[A11yNSAXElement alloc] initWithSession:a11y_session
                                                node:node
                                            callback:a11y_callback
                                       valueCallback:a11y_value_callback
                                      objectCallback:a11y_object_callback
                                             context:a11y_context]
            autorelease];
}

- (NSArray *)a11yCopyObjectsForSelector:(unsigned int)selector
                                operand:(unsigned int)operand {
    return [self a11yCopyObjectsForSelector:selector
                                    operand:operand
                                      pointX:0
                                      pointY:0];
}

- (NSArray *)a11yCopyObjectsForSelector:(unsigned int)selector
                                operand:(unsigned int)operand
                                  pointX:(long long)pointX
                                  pointY:(long long)pointY {
    unsigned long long items[128];
    unsigned long long item_count = 0;

    if (a11y_object_callback == 0) {
        return nil;
    }

    memset(items, 0, sizeof(items));

    if (a11y_object_callback(a11y_session,
                             a11y_node,
                             selector,
                             operand,
                             pointX,
                             pointY,
                             items,
                             128u,
                             &item_count,
                             a11y_context) == 0) {
        return nil;
    }
    if (item_count > 128u) {
        return nil;
    }

    NSMutableArray *array =
        [[NSMutableArray alloc] initWithCapacity:(NSUInteger)item_count];
    for (unsigned long long index = 0; index < item_count; ++index) {
        id element = [self a11yCreateElementForNode:items[index]];
        if (element != nil) {
            [array addObject:element];
        }
    }
    return [array autorelease];
}

- (unsigned long long)a11ySession {
    return a11y_session;
}

- (unsigned long long)a11yNode {
    return a11y_node;
}

- (NSArray *)accessibilityAttributeNames {
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_ATTRIBUTE_NAMES];
    id value = [self a11yCopyValueForSelector:A11Y_NSAX_SELECTOR_ATTRIBUTE_NAMES
                                      operand:0u];
    return [value isKindOfClass:[NSArray class]] ? value : [NSArray array];
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    unsigned int operand = a11y_nsax_attribute_operand(attribute);
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_ATTRIBUTE_VALUE
                       operand:operand];
    if (operand >= 1000u) {
        NSArray *items =
            [self a11yCopyObjectsForSelector:A11Y_NSAX_SELECTOR_ATTRIBUTE_VALUE
                                     operand:operand];
        return items != nil ? items : [NSArray array];
    }
    return [self a11yCopyValueForSelector:A11Y_NSAX_SELECTOR_ATTRIBUTE_VALUE
                                  operand:operand];
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    return [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_IS_ATTRIBUTE_SETTABLE
                              operand:a11y_nsax_attribute_operand(attribute)]
        != 0;
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    (void)value;
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_SET_VALUE
                       operand:a11y_nsax_attribute_operand(attribute)];
}

- (NSArray *)accessibilityActionNames {
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_ACTION_NAMES];
    id value = [self a11yCopyValueForSelector:A11Y_NSAX_SELECTOR_ACTION_NAMES
                                      operand:0u];
    return [value isKindOfClass:[NSArray class]] ? value : [NSArray array];
}

- (void)accessibilityPerformAction:(NSString *)action {
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_PERFORM_ACTION
                       operand:a11y_nsax_action_operand(action)];
}

- (id)accessibilityParent {
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_PARENT];
    NSArray *items = [self a11yCopyObjectsForSelector:A11Y_NSAX_SELECTOR_PARENT
                                              operand:0u];
    return [items count] > 0 ? [items objectAtIndex:0] : nil;
}

- (NSArray *)accessibilityChildren {
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_CHILDREN];
    NSArray *items =
        [self a11yCopyObjectsForSelector:A11Y_NSAX_SELECTOR_CHILDREN
                                 operand:0u];
    return items != nil ? items : [NSArray array];
}

- (id)accessibilityChildAtIndex:(NSInteger)index {
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_CHILD_AT_INDEX
                       operand:a11y_nsax_positive_index_operand(index)];
    NSArray *items =
        [self a11yCopyObjectsForSelector:A11Y_NSAX_SELECTOR_CHILD_AT_INDEX
                                 operand:a11y_nsax_positive_index_operand(index)];
    return [items count] > 0 ? [items objectAtIndex:0] : nil;
}

- (id)accessibilityHitTest:(NSPoint)point {
    long long point_x = 0;
    long long point_y = 0;
    if (point.x < (CGFloat)LLONG_MIN || point.x > (CGFloat)LLONG_MAX ||
        point.y < (CGFloat)LLONG_MIN || point.y > (CGFloat)LLONG_MAX) {
        return nil;
    }
    point_x = (long long)point.x;
    point_y = (long long)point.y;
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_HIT_TEST];
    NSArray *items =
        [self a11yCopyObjectsForSelector:A11Y_NSAX_SELECTOR_HIT_TEST
                                 operand:0u
                                   pointX:point_x
                                   pointY:point_y];
    return [items count] > 0 ? [items objectAtIndex:0] : nil;
}

- (id)accessibilityFocusedUIElement {
    [self a11yDispatchSelector:A11Y_NSAX_SELECTOR_FOCUSED_UI_ELEMENT];
    NSArray *items =
        [self a11yCopyObjectsForSelector:A11Y_NSAX_SELECTOR_FOCUSED_UI_ELEMENT
                                 operand:0u];
    return [items count] > 0 ? [items objectAtIndex:0] : nil;
}

- (void)accessibilityPostNotification:(NSString *)notification {
    unsigned int operand = a11y_nsax_notification_operand(notification);
    if ([self a11yDispatchSelector:A11Y_NSAX_SELECTOR_POST_NOTIFICATION
                           operand:operand] != 0
        && notification != nil) {
        NSAccessibilityPostNotification(self, notification);
    }
}
@end

@implementation A11yNSAXHostView
- (id)initWithFrame:(NSRect)frame root:(A11yNSAXElement *)root {
    self = [super initWithFrame:frame];
    if (self != nil) {
        a11y_root = [root retain];
        [self setAccessibilityElement:NO];
    }
    return self;
}

- (void)dealloc {
    [a11y_root release];
    [super dealloc];
}

- (NSArray *)accessibilityChildren {
    return a11y_root != nil ? [NSArray arrayWithObject:a11y_root] : [NSArray array];
}

- (id)accessibilityHitTest:(NSPoint)point {
    (void)point;
    return a11y_root;
}

- (id)accessibilityFocusedUIElement {
    return a11y_root;
}
@end

@implementation A11yNSAXProcessRootHost
- (id)initWithRoot:(A11yNSAXElement *)root {
    self = [super init];
    if (self != nil) {
        NSRect frame = NSMakeRect(32.0, 32.0, 96.0, 64.0);
        a11y_root = [root retain];
        a11y_view = [[A11yNSAXHostView alloc] initWithFrame:frame root:a11y_root];
        a11y_window = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:NSWindowStyleMaskBorderless
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
        if (a11y_window == nil || a11y_view == nil) {
            [self release];
            return nil;
        }
        [a11y_window setReleasedWhenClosed:NO];
        [a11y_window setContentView:a11y_view];
        [a11y_window setAccessibilityElement:YES];
        [a11y_window setAccessibilityChildren:[NSArray arrayWithObject:a11y_view]];
        [a11y_window orderFrontRegardless];
    }
    return self;
}

- (void)dealloc {
    [a11y_window orderOut:nil];
    [a11y_window close];
    [a11y_window release];
    [a11y_view release];
    [a11y_root release];
    [super dealloc];
}

- (int)a11yPostNotificationCode:(unsigned int)notification {
    NSString *name = a11y_nsax_notification_name(notification);
    if (name == nil || a11y_root == nil) {
        return 0;
    }
    [a11y_root accessibilityPostNotification:name];
    return 1;
}
@end
#endif

static int a11y_nsax_bounded_utf8_length(const char *text,
                                         unsigned long long *length) {
    unsigned long long index;

    if (text == 0 || length == 0) {
        return 0;
    }

    for (index = 0; index <= A11Y_NSAX_MAX_UTF8_BYTES; ++index) {
        if (text[index] == '\0') {
            *length = index;
            return 1;
        }
    }

    return 0;
}

unsigned int a11y_nsax_bridge_is_macos(void) {
#if defined(__APPLE__) && defined(__MACH__)
    return 1;
#else
    return 0;
#endif
}

void *a11y_nsax_create_autorelease_pool(void) {
    @try {
        return [[NSAutoreleasePool alloc] init];
    } @catch (...) {
        return 0;
    }
}

void a11y_nsax_drain_autorelease_pool(void *pool) {
    @try {
        [(id)pool drain];
    } @catch (...) {
    }
}

void *a11y_nsax_retain_object(void *object) {
    @try {
        return [(id)object retain];
    } @catch (...) {
        return 0;
    }
}

void a11y_nsax_release_object(void *object) {
    @try {
        [(id)object release];
    } @catch (...) {
    }
}

void *a11y_nsax_copy_utf8_string(const char *text) {
    @try {
        unsigned long long length = 0;

        if (text == 0) {
            return 0;
        }
        if (!a11y_nsax_bounded_utf8_length(text, &length)) {
            return 0;
        }
        if (length > (unsigned long long)NSUIntegerMax) {
            return 0;
        }
        return [[NSString alloc] initWithBytes:text
                                        length:(NSUInteger)length
                                      encoding:NSUTF8StringEncoding];
    } @catch (...) {
        return 0;
    }
}

void *a11y_nsax_copy_uint32_array(const unsigned int *items,
                                  unsigned long long count) {
    @try {
        if (items == 0 && count != 0) {
            return 0;
        }
        if (count > A11Y_NSAX_MAX_ARRAY_COUNT ||
            count > (unsigned long long)NSUIntegerMax) {
            return 0;
        }

        NSMutableArray *array =
            [[NSMutableArray alloc] initWithCapacity:(NSUInteger)count];
        for (unsigned long long index = 0; index < count; ++index) {
            [array addObject:[NSNumber numberWithUnsignedInt:items[index]]];
        }
        return array;
    } @catch (...) {
        return 0;
    }
}

void *a11y_nsax_create_virtual_element(a11y_nsax_callback callback,
                                       unsigned long long session,
                                       unsigned long long node,
                                       void *context) {
#if defined(__APPLE__) && defined(__MACH__)
    @try {
        if (callback == 0 || session == 0 || node == 0) {
            return 0;
        }
        return [[A11yNSAXElement alloc] initWithSession:session
                                                   node:node
                                               callback:callback
                                          valueCallback:0
                                         objectCallback:0
                                                context:context];
    } @catch (...) {
        return 0;
    }
#else
    (void)callback;
    (void)session;
    (void)node;
    (void)context;
    return 0;
#endif
}

void *a11y_nsax_create_virtual_element_with_value_callback(
    a11y_nsax_callback callback,
    a11y_nsax_value_callback value_callback,
    unsigned long long session,
    unsigned long long node,
    void *context) {
#if defined(__APPLE__) && defined(__MACH__)
    @try {
        if (callback == 0 || value_callback == 0 || session == 0 ||
            node == 0) {
            return 0;
        }
        return [[A11yNSAXElement alloc] initWithSession:session
                                                   node:node
                                               callback:callback
                                          valueCallback:value_callback
                                         objectCallback:0
                                                context:context];
    } @catch (...) {
        return 0;
    }
#else
    (void)callback;
    (void)value_callback;
    (void)session;
    (void)node;
    (void)context;
    return 0;
#endif
}

void *a11y_nsax_create_virtual_element_with_callbacks(
    a11y_nsax_callback callback,
    a11y_nsax_value_callback value_callback,
    a11y_nsax_object_callback object_callback,
    unsigned long long session,
    unsigned long long node,
    void *context) {
#if defined(__APPLE__) && defined(__MACH__)
    @try {
        if (callback == 0 || value_callback == 0 || object_callback == 0 ||
            session == 0 || node == 0) {
            return 0;
        }
        return [[A11yNSAXElement alloc] initWithSession:session
                                                   node:node
                                               callback:callback
                                          valueCallback:value_callback
                                         objectCallback:object_callback
                                                context:context];
    } @catch (...) {
        return 0;
    }
#else
    (void)callback;
    (void)value_callback;
    (void)object_callback;
    (void)session;
    (void)node;
    (void)context;
    return 0;
#endif
}

void *a11y_nsax_install_process_root(
    a11y_nsax_callback callback,
    a11y_nsax_value_callback value_callback,
    a11y_nsax_object_callback object_callback,
    unsigned long long session,
    unsigned long long node,
    void *context) {
#if defined(__APPLE__) && defined(__MACH__)
    A11yNSAXElement *root = nil;

    @try {
        if (callback == 0 || value_callback == 0 || object_callback == 0 ||
            session == 0 || node == 0) {
            return 0;
        }

        [NSApplication sharedApplication];
        root = [[A11yNSAXElement alloc] initWithSession:session
                                                   node:node
                                               callback:callback
                                          valueCallback:value_callback
                                         objectCallback:object_callback
                                                context:context];
        if (root == nil) {
            return 0;
        }

        A11yNSAXProcessRootHost *host =
            [[A11yNSAXProcessRootHost alloc] initWithRoot:root];
        [root release];
        return host;
    } @catch (...) {
        if (root != nil) {
            [root release];
        }
        return 0;
    }
#else
    (void)callback;
    (void)value_callback;
    (void)object_callback;
    (void)session;
    (void)node;
    (void)context;
    return 0;
#endif
}

unsigned int a11y_nsax_virtual_element_matches(void *object,
                                              unsigned long long session,
                                              unsigned long long node) {
#if defined(__APPLE__) && defined(__MACH__)
    @try {
        if (object == 0 || session == 0 || node == 0) {
            return 0;
        }
        if (![(id)object isKindOfClass:[A11yNSAXElement class]]) {
            return 0;
        }
        A11yNSAXElement *element = (A11yNSAXElement *)object;
        return ([element a11ySession] == session && [element a11yNode] == node)
            ? 1u
            : 0u;
    } @catch (...) {
        return 0;
    }
#else
    (void)object;
    (void)session;
    (void)node;
    return 0;
#endif
}

unsigned int a11y_nsax_probe_virtual_element_bridge(
    a11y_nsax_callback callback,
    unsigned long long session,
    unsigned long long node,
    void *context) {
#if defined(__APPLE__) && defined(__MACH__)
    A11yNSAXElement *element = nil;
    unsigned int mask = 0;

    @try {
        if (callback == 0 || session == 0 || node == 0) {
            return 0;
        }

        @autoreleasepool {
            element = [[A11yNSAXElement alloc] initWithSession:session
                                                          node:node
                                                      callback:callback
                                                valueCallback:0
                                               objectCallback:0
                                                       context:context];
            if (element == nil) {
                return 0;
            }
            mask |= A11Y_NSAX_PROBE_ELEMENT_CREATED;

            if (a11y_nsax_virtual_element_matches(element, session, node) != 0) {
                mask |= A11Y_NSAX_PROBE_IDENTITY_MATCHED;
            }

            [element accessibilityAttributeNames];
            mask |= A11Y_NSAX_PROBE_ATTRIBUTE_NAMES_DISPATCHED;
            [element accessibilityAttributeValue:@"AXRole"];
            mask |= A11Y_NSAX_PROBE_ATTRIBUTE_VALUE_DISPATCHED;
            [element accessibilityIsAttributeSettable:@"AXValue"];
            mask |= A11Y_NSAX_PROBE_SETTABLE_DISPATCHED;
            [element accessibilityActionNames];
            mask |= A11Y_NSAX_PROBE_ACTION_NAMES_DISPATCHED;
            [element accessibilityParent];
            mask |= A11Y_NSAX_PROBE_PARENT_DISPATCHED;
            [element accessibilityChildren];
            mask |= A11Y_NSAX_PROBE_CHILDREN_DISPATCHED;
            [element accessibilityChildAtIndex:0];
            mask |= A11Y_NSAX_PROBE_CHILD_AT_INDEX_DISPATCHED;
            [element accessibilityHitTest:NSMakePoint(0.0, 0.0)];
            mask |= A11Y_NSAX_PROBE_HIT_TEST_DISPATCHED;
            [element accessibilityFocusedUIElement];
            mask |= A11Y_NSAX_PROBE_FOCUSED_DISPATCHED;
            [element accessibilityPostNotification:NSAccessibilityCreatedNotification];
            mask |= A11Y_NSAX_PROBE_NOTIFICATION_DISPATCHED;

            [element release];
            element = nil;
            mask |= A11Y_NSAX_PROBE_RELEASED;
        }

        return mask;
    } @catch (...) {
        if (element != nil) {
            [element release];
        }
        return 0;
    }
#else
    (void)callback;
    (void)session;
    (void)node;
    (void)context;
    return 0;
#endif
}

unsigned int a11y_nsax_probe_value_returning_virtual_element_bridge(
    a11y_nsax_callback callback,
    a11y_nsax_value_callback value_callback,
    unsigned long long session,
    unsigned long long node,
    void *context) {
#if defined(__APPLE__) && defined(__MACH__)
    A11yNSAXElement *element = nil;
    unsigned int mask = 0;

    @try {
        if (callback == 0 || value_callback == 0 || session == 0 ||
            node == 0) {
            return 0;
        }

        @autoreleasepool {
            element = [[A11yNSAXElement alloc] initWithSession:session
                                                          node:node
                                                      callback:callback
                                                 valueCallback:value_callback
                                                objectCallback:0
                                                       context:context];
            if (element == nil) {
                return 0;
            }
            mask |= A11Y_NSAX_PROBE_ELEMENT_CREATED;

            if (a11y_nsax_virtual_element_matches(element, session, node) != 0) {
                mask |= A11Y_NSAX_PROBE_IDENTITY_MATCHED;
            }
            if ([[element accessibilityAttributeNames] count] > 0) {
                mask |= A11Y_NSAX_PROBE_ATTRIBUTE_NAMES_DISPATCHED;
            }
            if ([element accessibilityAttributeValue:@"AXRole"] != nil &&
                [element accessibilityAttributeValue:@"AXFrame"] != nil) {
                mask |= A11Y_NSAX_PROBE_ATTRIBUTE_VALUE_DISPATCHED;
            }
            if ([[element accessibilityActionNames] count] > 0) {
                mask |= A11Y_NSAX_PROBE_ACTION_NAMES_DISPATCHED;
            }

            [element release];
            element = nil;
            mask |= A11Y_NSAX_PROBE_RELEASED;
        }

        return mask;
    } @catch (...) {
        if (element != nil) {
            [element release];
        }
        return 0;
    }
#else
    (void)callback;
    (void)value_callback;
    (void)session;
    (void)node;
    (void)context;
    return 0;
#endif
}

unsigned int a11y_nsax_probe_object_returning_virtual_element_bridge(
    a11y_nsax_callback callback,
    a11y_nsax_value_callback value_callback,
    a11y_nsax_object_callback object_callback,
    unsigned long long session,
    unsigned long long node,
    void *context) {
#if defined(__APPLE__) && defined(__MACH__)
    A11yNSAXElement *element = nil;
    unsigned int mask = 0;

    @try {
        if (callback == 0 || value_callback == 0 || object_callback == 0 ||
            session == 0 || node == 0) {
            return 0;
        }

        @autoreleasepool {
            element = [[A11yNSAXElement alloc] initWithSession:session
                                                          node:node
                                                      callback:callback
                                                 valueCallback:value_callback
                                                objectCallback:object_callback
                                                       context:context];
            if (element == nil) {
                return 0;
            }
            mask |= A11Y_NSAX_PROBE_ELEMENT_CREATED;

            NSArray *children = [element accessibilityChildren];
            if ([children count] > 0) {
                mask |= A11Y_NSAX_PROBE_CHILDREN_DISPATCHED;
                id child = [children objectAtIndex:0];
                if (a11y_nsax_virtual_element_matches(child, session, 3u) != 0) {
                    mask |= A11Y_NSAX_PROBE_IDENTITY_MATCHED;
                }
            }

            if ([element accessibilityChildAtIndex:0] != nil) {
                mask |= A11Y_NSAX_PROBE_CHILD_AT_INDEX_DISPATCHED;
            }
            id title_element = [element accessibilityAttributeValue:@"AXTitleUIElement"];
            if ([title_element isKindOfClass:[NSArray class]] &&
                [(NSArray *)title_element count] > 0) {
                mask |= A11Y_NSAX_PROBE_ATTRIBUTE_VALUE_DISPATCHED;
            }
            if ([element accessibilityHitTest:NSMakePoint(0.0, 0.0)] != nil) {
                mask |= A11Y_NSAX_PROBE_HIT_TEST_DISPATCHED;
            }
            if ([element accessibilityFocusedUIElement] != nil) {
                mask |= A11Y_NSAX_PROBE_FOCUSED_DISPATCHED;
            }

            [element release];
            element = nil;
            mask |= A11Y_NSAX_PROBE_RELEASED;
        }

        return mask;
    } @catch (...) {
        if (element != nil) {
            [element release];
        }
        return 0;
    }
#else
    (void)callback;
    (void)value_callback;
    (void)object_callback;
    (void)session;
    (void)node;
    (void)context;
    return 0;
#endif
}

unsigned int a11y_nsax_probe_public_ax_client_for_pid(int process_id) {
#if defined(__APPLE__) && defined(__MACH__)
    AXUIElementRef application = 0;
    CFArrayRef attribute_names = 0;
    CFTypeRef role_value = 0;
    CFTypeRef windows_value = 0;
    CFTypeRef children_value = 0;
    CFTypeRef root_role_value = 0;
    unsigned int mask = 0;

    @try {
        if (process_id <= 0) {
            return 0;
        }

        (void)AXIsProcessTrusted();
        mask |= A11Y_NSAX_PUBLIC_AX_PROBE_TRUST_CHECKED;

        application = AXUIElementCreateApplication((pid_t)process_id);
        if (application == 0) {
            return mask;
        }
        mask |= A11Y_NSAX_PUBLIC_AX_PROBE_APPLICATION_CREATED;

        (void)AXUIElementCopyAttributeNames(application, &attribute_names);
        mask |= A11Y_NSAX_PUBLIC_AX_PROBE_ATTRIBUTE_NAMES_ATTEMPTED;
        if (attribute_names != 0) {
            CFRelease(attribute_names);
            attribute_names = 0;
        }

        (void)AXUIElementCopyAttributeValue(application,
                                           kAXRoleAttribute,
                                           &role_value);
        mask |= A11Y_NSAX_PUBLIC_AX_PROBE_ROLE_ATTEMPTED;
        if (role_value != 0) {
            CFRelease(role_value);
            role_value = 0;
        }

        (void)AXUIElementCopyAttributeValue(application,
                                           kAXWindowsAttribute,
                                           &windows_value);
        mask |= A11Y_NSAX_PUBLIC_AX_PROBE_WINDOWS_ATTEMPTED;
        if (windows_value != 0 && CFGetTypeID(windows_value) == CFArrayGetTypeID() &&
            CFArrayGetCount((CFArrayRef)windows_value) > 0) {
            AXUIElementRef window =
                (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)windows_value, 0);
            (void)AXUIElementCopyAttributeValue(window,
                                               kAXChildrenAttribute,
                                               &children_value);
            mask |= A11Y_NSAX_PUBLIC_AX_PROBE_WINDOW_CHILDREN_ATTEMPTED;
            if (children_value != 0 &&
                CFGetTypeID(children_value) == CFArrayGetTypeID() &&
                CFArrayGetCount((CFArrayRef)children_value) > 0) {
                AXUIElementRef child =
                    (AXUIElementRef)CFArrayGetValueAtIndex((CFArrayRef)children_value, 0);
                (void)AXUIElementCopyAttributeValue(child,
                                                   kAXRoleAttribute,
                                                   &root_role_value);
                mask |= A11Y_NSAX_PUBLIC_AX_PROBE_ROOT_ROLE_ATTEMPTED;
            }
        }
        if (root_role_value != 0) {
            CFRelease(root_role_value);
            root_role_value = 0;
        }
        if (children_value != 0) {
            CFRelease(children_value);
            children_value = 0;
        }
        if (windows_value != 0) {
            CFRelease(windows_value);
            windows_value = 0;
        }

        CFRelease(application);
        application = 0;
        mask |= A11Y_NSAX_PUBLIC_AX_PROBE_RELEASED;

        return mask;
    } @catch (...) {
        if (root_role_value != 0) {
            CFRelease(root_role_value);
        }
        if (children_value != 0) {
            CFRelease(children_value);
        }
        if (windows_value != 0) {
            CFRelease(windows_value);
        }
        if (role_value != 0) {
            CFRelease(role_value);
        }
        if (attribute_names != 0) {
            CFRelease(attribute_names);
        }
        if (application != 0) {
            CFRelease(application);
        }
        return 0;
    }
#else
    (void)process_id;
    return 0;
#endif
}

int a11y_nsax_dispatch_selector(a11y_nsax_callback callback,
                                unsigned long long session,
                                unsigned long long node,
                                unsigned int selector,
                                void *context) {
    if (callback == 0) {
        return 0;
    }
    return callback(session, node, selector, 0u, context);
}

int a11y_nsax_dispatch_selector_frame(a11y_nsax_callback callback,
                                      const unsigned long long *frame,
                                      void *context) {
    if (callback == 0 || frame == 0) {
        return 0;
    }
    return callback(frame[0],
                    frame[1],
                    (unsigned int)frame[2],
                    (unsigned int)frame[3],
                    context);
}

int a11y_nsax_post_notification(a11y_nsax_callback callback,
                                unsigned long long session,
                                unsigned long long node,
                                unsigned int notification,
                                void *context) {
    if (callback == 0) {
        return 0;
    }
    return callback(session,
                    node,
                    A11Y_NSAX_SELECTOR_POST_NOTIFICATION,
                    notification,
                    context);
}

int a11y_nsax_post_notification_for_object(void *object,
                                           unsigned int notification) {
#if defined(__APPLE__) && defined(__MACH__)
    @try {
        if (object == 0 || notification == 0u) {
            return 0;
        }
        id target = (id)object;
        if ([target isKindOfClass:[A11yNSAXProcessRootHost class]]) {
            return [(A11yNSAXProcessRootHost *)target
                a11yPostNotificationCode:notification];
        }
        if ([target isKindOfClass:[A11yNSAXElement class]]) {
            NSString *name = a11y_nsax_notification_name(notification);
            if (name == nil) {
                return 0;
            }
            [(A11yNSAXElement *)target accessibilityPostNotification:name];
            return 1;
        }
        return 0;
    } @catch (...) {
        return 0;
    }
#else
    (void)object;
    (void)notification;
    return 0;
#endif
}
