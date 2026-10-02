/*
 * Minimal UI Automation ABI bridge.
 *
 * This file intentionally contains no accessibility semantics. Control type
 * mapping, property mapping, pattern selection, fragment navigation policy,
 * event coalescing, and provider dispatch live in Ada backend-private packages.
 */

#include <stddef.h>
#include <stdint.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#define COBJMACROS
#include <windows.h>
#include <oleauto.h>
#include <uiautomation.h>
#endif

typedef int32_t a11y_uia_hresult;
typedef uint32_t (*a11y_uia_callback)(uint64_t session,
                                      uint64_t provider,
                                      uint32_t method,
                                      void *context);
typedef uint32_t (*a11y_uia_frame_callback)(const uint64_t *frame,
                                            void *context);
typedef uint32_t (*a11y_uia_value_callback)(const uint64_t *frame,
                                            uint32_t native_property,
                                            uint32_t *value_kind,
                                            char *utf8_buffer,
                                            uint32_t utf8_capacity,
                                            uint32_t *utf8_used,
                                            void *context);
typedef uint32_t (*a11y_uia_uint32_array_callback)(const uint64_t *frame,
                                                   uint32_t *value_kind,
                                                   uint32_t *items,
                                                   uint32_t capacity,
                                                   uint32_t *used,
                                                   void *context);
typedef uint32_t (*a11y_uia_rectangle_callback)(const uint64_t *frame,
                                                double *left,
                                                double *top,
                                                double *width,
                                                double *height,
                                                void *context);
typedef uint32_t (*a11y_uia_boolean_callback)(const uint64_t *frame,
                                              uint32_t *value,
                                              void *context);
typedef uint32_t (*a11y_uia_pattern_callback)(const uint64_t *frame,
                                              uint32_t native_pattern,
                                              uint32_t *supported,
                                              void *context);
typedef uint32_t (*a11y_uia_state_callback)(const uint64_t *frame,
                                            uint32_t native_state_kind,
                                            uint32_t *state,
                                            void *context);
typedef uint32_t (*a11y_uia_range_value_callback)(const uint64_t *frame,
                                                  double value,
                                                  void *context);
typedef uint32_t (*a11y_uia_range_value_query_callback)(const uint64_t *frame,
                                                        double *numeric_value,
                                                        uint32_t *boolean_value,
                                                        void *context);
typedef uint32_t (*a11y_uia_window_query_callback)(const uint64_t *frame,
                                                   uint32_t *value,
                                                   void *context);

uint32_t a11y_uia_bridge_is_windows(void)
{
#if defined(_WIN32)
    return 1;
#else
    return 0;
#endif
}

struct a11y_uia_client_runtime_probe {
    uint32_t coinitialized;
    uint32_t automation_created;
    uint32_t root_element_obtained;
    uint32_t root_name_obtained;
    uint32_t client_runtime_available;
    int32_t coinitialize_hresult;
    int32_t cocreate_hresult;
    int32_t get_root_hresult;
    int32_t get_name_hresult;
};

struct a11y_uia_host_window_probe {
    uint32_t window_class_registered;
    uint32_t window_created;
    uint32_t wm_getobject_sent;
    uint32_t uia_root_object_id_matched;
    uint32_t return_raw_element_provider_called;
    uint32_t null_provider_returned_zero;
    uint32_t window_destroyed;
    int32_t register_error;
    int32_t create_error;
    int32_t return_raw_element_provider_lresult;
};

struct a11y_uia_minimal_provider_host_window_probe {
    uint32_t coinitialized;
    uint32_t window_class_registered;
    uint32_t window_created;
    uint32_t provider_created;
    uint32_t wm_getobject_sent;
    uint32_t uia_root_object_id_matched;
    uint32_t return_raw_element_provider_called;
    uint32_t return_raw_element_provider_nonzero;
    uint32_t provider_query_interface_called;
    uint32_t provider_add_ref_called;
    uint32_t provider_release_called;
    uint32_t provider_options_called;
    uint32_t element_from_handle_called;
    uint32_t element_from_handle_succeeded;
    uint32_t window_destroyed;
    uint32_t provider_final_ref_count;
    int32_t coinitialize_hresult;
    int32_t register_error;
    int32_t create_error;
    int32_t return_raw_element_provider_lresult;
    int32_t cocreate_hresult;
    int32_t element_from_handle_hresult;
};

struct a11y_uia_callback_provider_host_window_probe {
    uint32_t coinitialized;
    uint32_t window_class_registered;
    uint32_t window_created;
    uint32_t provider_created;
    uint32_t wm_getobject_sent;
    uint32_t uia_root_object_id_matched;
    uint32_t return_raw_element_provider_called;
    uint32_t return_raw_element_provider_nonzero;
    uint32_t provider_query_interface_called;
    uint32_t provider_add_ref_called;
    uint32_t provider_release_called;
    uint32_t provider_options_called;
    uint32_t provider_options_callback_called;
    uint32_t provider_options_callback_succeeded;
    uint32_t pattern_provider_called;
    uint32_t pattern_provider_callback_called;
    uint32_t pattern_provider_callback_succeeded;
    uint32_t pattern_provider_support_callback_called;
    uint32_t pattern_provider_support_callback_succeeded;
    uint32_t pattern_provider_returned_invoke;
    uint32_t pattern_provider_returned_toggle;
    uint32_t pattern_provider_returned_expand_collapse;
    uint32_t pattern_provider_returned_scroll_item;
    uint32_t pattern_provider_returned_selection_item;
    uint32_t pattern_provider_returned_range_value;
    uint32_t pattern_provider_returned_window;
    uint32_t invoke_provider_invoke_called;
    uint32_t invoke_provider_invoke_callback_called;
    uint32_t invoke_provider_invoke_callback_succeeded;
    uint32_t toggle_provider_toggle_called;
    uint32_t toggle_provider_toggle_callback_called;
    uint32_t toggle_provider_toggle_callback_succeeded;
    uint32_t toggle_provider_get_state_called;
    uint32_t toggle_provider_get_state_callback_called;
    uint32_t toggle_provider_get_state_callback_succeeded;
    uint32_t toggle_provider_state;
    uint32_t expand_collapse_provider_expand_called;
    uint32_t expand_collapse_provider_expand_callback_called;
    uint32_t expand_collapse_provider_expand_callback_succeeded;
    uint32_t expand_collapse_provider_collapse_called;
    uint32_t expand_collapse_provider_collapse_callback_called;
    uint32_t expand_collapse_provider_collapse_callback_succeeded;
    uint32_t expand_collapse_provider_get_state_called;
    uint32_t expand_collapse_provider_get_state_callback_called;
    uint32_t expand_collapse_provider_get_state_callback_succeeded;
    uint32_t expand_collapse_provider_state;
    uint32_t scroll_item_provider_scroll_into_view_called;
    uint32_t scroll_item_provider_scroll_into_view_callback_called;
    uint32_t scroll_item_provider_scroll_into_view_callback_succeeded;
    uint32_t selection_item_provider_select_called;
    uint32_t selection_item_provider_select_callback_called;
    uint32_t selection_item_provider_select_callback_succeeded;
    uint32_t selection_item_provider_add_to_selection_called;
    uint32_t selection_item_provider_add_to_selection_callback_called;
    uint32_t selection_item_provider_add_to_selection_callback_succeeded;
    uint32_t selection_item_provider_remove_from_selection_called;
    uint32_t selection_item_provider_remove_from_selection_callback_called;
    uint32_t selection_item_provider_remove_from_selection_callback_succeeded;
    uint32_t selection_item_provider_get_is_selected_called;
    uint32_t selection_item_provider_get_is_selected_callback_called;
    uint32_t selection_item_provider_get_is_selected_callback_succeeded;
    uint32_t selection_item_provider_is_selected;
    uint32_t selection_item_provider_get_selection_container_called;
    uint32_t selection_item_provider_get_selection_container_callback_called;
    uint32_t selection_item_provider_get_selection_container_callback_succeeded;
    uint32_t selection_item_provider_returned_selection_container;
    uint32_t range_value_provider_set_value_called;
    uint32_t range_value_provider_set_value_callback_called;
    uint32_t range_value_provider_set_value_callback_succeeded;
    uint32_t range_value_provider_get_value_callback_succeeded;
    uint32_t range_value_provider_get_is_read_only_callback_succeeded;
    uint32_t range_value_provider_get_maximum_callback_succeeded;
    uint32_t range_value_provider_get_minimum_callback_succeeded;
    uint32_t range_value_provider_get_large_change_callback_succeeded;
    uint32_t range_value_provider_get_small_change_callback_succeeded;
    uint32_t window_provider_close_called;
    uint32_t window_provider_close_callback_called;
    uint32_t window_provider_close_callback_succeeded;
    uint32_t window_provider_get_can_maximize_callback_succeeded;
    uint32_t window_provider_get_can_minimize_callback_succeeded;
    uint32_t window_provider_get_is_modal_callback_succeeded;
    uint32_t window_provider_get_visual_state_callback_succeeded;
    uint32_t window_provider_get_interaction_state_callback_succeeded;
    uint32_t advise_events_advise_called;
    uint32_t advise_events_advise_callback_called;
    uint32_t advise_events_advise_callback_succeeded;
    uint32_t advise_events_unadvise_called;
    uint32_t advise_events_unadvise_callback_called;
    uint32_t advise_events_unadvise_callback_succeeded;
    uint32_t property_value_called;
    uint32_t property_value_callback_called;
    uint32_t property_value_callback_succeeded;
    uint32_t host_raw_element_provider_called;
    uint32_t host_raw_element_provider_callback_called;
    uint32_t host_raw_element_provider_callback_succeeded;
    uint32_t host_raw_element_provider_returned_host;
    uint32_t fragment_query_interface_called;
    uint32_t fragment_query_interface_succeeded;
    uint32_t fragment_navigate_called;
    uint32_t fragment_navigate_callback_called;
    uint32_t fragment_navigate_callback_succeeded;
    uint32_t fragment_runtime_id_called;
    uint32_t fragment_runtime_id_callback_called;
    uint32_t fragment_runtime_id_callback_succeeded;
    uint32_t fragment_bounding_rectangle_called;
    uint32_t fragment_bounding_rectangle_callback_called;
    uint32_t fragment_bounding_rectangle_callback_succeeded;
    uint32_t fragment_embedded_roots_called;
    uint32_t fragment_embedded_roots_callback_called;
    uint32_t fragment_embedded_roots_callback_succeeded;
    uint32_t fragment_set_focus_called;
    uint32_t fragment_set_focus_callback_called;
    uint32_t fragment_set_focus_callback_succeeded;
    uint32_t fragment_root_called;
    uint32_t fragment_root_callback_called;
    uint32_t fragment_root_callback_succeeded;
    uint32_t fragment_root_query_interface_called;
    uint32_t fragment_root_query_interface_succeeded;
    uint32_t root_from_point_called;
    uint32_t root_from_point_callback_called;
    uint32_t root_from_point_callback_succeeded;
    uint32_t root_from_point_returned_fragment;
    uint32_t root_get_focus_called;
    uint32_t root_get_focus_callback_called;
    uint32_t root_get_focus_callback_succeeded;
    uint32_t root_get_focus_returned_fragment;
    uint32_t full_frame_callback_called;
    uint32_t full_frame_callback_succeeded;
    uint32_t full_frame_simple_count;
    uint32_t full_frame_fragment_count;
    uint32_t full_frame_root_count;
    uint32_t full_frame_advise_events_count;
    uint32_t window_destroyed;
    uint32_t provider_final_ref_count;
    uint64_t options_callback_session;
    uint64_t options_callback_provider;
    uint32_t options_callback_method;
    uint32_t options_callback_hresult;
    uint64_t property_callback_session;
    uint64_t property_callback_provider;
    uint32_t property_callback_method;
    uint32_t property_callback_hresult;
    uint64_t pattern_callback_session;
    uint64_t pattern_callback_provider;
    uint32_t pattern_callback_method;
    uint32_t pattern_callback_hresult;
    uint64_t host_callback_session;
    uint64_t host_callback_provider;
    uint32_t host_callback_method;
    uint32_t host_callback_hresult;
    uint32_t fragment_navigate_callback_method;
    uint32_t fragment_navigate_callback_hresult;
    uint32_t fragment_runtime_id_callback_method;
    uint32_t fragment_runtime_id_callback_hresult;
    uint32_t fragment_bounding_rectangle_callback_method;
    uint32_t fragment_bounding_rectangle_callback_hresult;
    uint32_t fragment_embedded_roots_callback_method;
    uint32_t fragment_embedded_roots_callback_hresult;
    uint32_t fragment_set_focus_callback_method;
    uint32_t fragment_set_focus_callback_hresult;
    uint32_t fragment_root_callback_method;
    uint32_t fragment_root_callback_hresult;
    uint32_t root_from_point_callback_method;
    uint32_t root_from_point_callback_hresult;
    uint32_t root_get_focus_callback_method;
    uint32_t root_get_focus_callback_hresult;
    uint32_t invoke_provider_invoke_callback_method;
    uint32_t invoke_provider_invoke_callback_hresult;
    uint32_t toggle_provider_toggle_callback_method;
    uint32_t toggle_provider_toggle_callback_hresult;
    uint32_t toggle_provider_get_state_callback_hresult;
    uint32_t expand_collapse_provider_expand_callback_method;
    uint32_t expand_collapse_provider_expand_callback_hresult;
    uint32_t expand_collapse_provider_collapse_callback_method;
    uint32_t expand_collapse_provider_collapse_callback_hresult;
    uint32_t expand_collapse_provider_get_state_callback_hresult;
    uint32_t scroll_item_provider_scroll_into_view_callback_method;
    uint32_t scroll_item_provider_scroll_into_view_callback_hresult;
    uint32_t selection_item_provider_select_callback_method;
    uint32_t selection_item_provider_select_callback_hresult;
    uint32_t selection_item_provider_add_to_selection_callback_method;
    uint32_t selection_item_provider_add_to_selection_callback_hresult;
    uint32_t selection_item_provider_remove_from_selection_callback_method;
    uint32_t selection_item_provider_remove_from_selection_callback_hresult;
    uint32_t selection_item_provider_get_is_selected_callback_method;
    uint32_t selection_item_provider_get_is_selected_callback_hresult;
    uint32_t selection_item_provider_get_selection_container_callback_method;
    uint32_t selection_item_provider_get_selection_container_callback_hresult;
    uint32_t range_value_provider_set_value_callback_method;
    uint32_t range_value_provider_set_value_callback_hresult;
    uint32_t range_value_provider_get_value_callback_method;
    uint32_t range_value_provider_get_value_callback_hresult;
    uint32_t range_value_provider_get_is_read_only_callback_method;
    uint32_t range_value_provider_get_is_read_only_callback_hresult;
    uint32_t range_value_provider_get_maximum_callback_method;
    uint32_t range_value_provider_get_maximum_callback_hresult;
    uint32_t range_value_provider_get_minimum_callback_method;
    uint32_t range_value_provider_get_minimum_callback_hresult;
    uint32_t range_value_provider_get_large_change_callback_method;
    uint32_t range_value_provider_get_large_change_callback_hresult;
    uint32_t range_value_provider_get_small_change_callback_method;
    uint32_t range_value_provider_get_small_change_callback_hresult;
    uint32_t window_provider_close_callback_method;
    uint32_t window_provider_close_callback_hresult;
    uint32_t window_provider_get_can_maximize_callback_method;
    uint32_t window_provider_get_can_maximize_callback_hresult;
    uint32_t window_provider_get_can_minimize_callback_method;
    uint32_t window_provider_get_can_minimize_callback_hresult;
    uint32_t window_provider_get_is_modal_callback_method;
    uint32_t window_provider_get_is_modal_callback_hresult;
    uint32_t window_provider_get_visual_state_callback_method;
    uint32_t window_provider_get_visual_state_callback_hresult;
    uint32_t window_provider_get_interaction_state_callback_method;
    uint32_t window_provider_get_interaction_state_callback_hresult;
    uint32_t advise_events_advise_callback_method;
    uint32_t advise_events_advise_callback_hresult;
    uint32_t advise_events_unadvise_callback_method;
    uint32_t advise_events_unadvise_callback_hresult;
    uint64_t full_frame_session;
    uint64_t full_frame_provider;
    uint64_t full_frame_object_token;
    uint64_t full_frame_interface;
    uint64_t full_frame_method;
    uint64_t full_frame_direction;
    uint64_t full_frame_point_x;
    uint64_t full_frame_point_y;
    uint32_t full_frame_hresult;
    int32_t coinitialize_hresult;
    int32_t register_error;
    int32_t create_error;
    int32_t return_raw_element_provider_lresult;
    int32_t provider_options_hresult;
    int32_t property_value_hresult;
    int32_t pattern_provider_hresult;
    int32_t host_raw_element_provider_hresult;
    int32_t fragment_navigate_hresult;
    int32_t fragment_runtime_id_hresult;
    int32_t fragment_bounding_rectangle_hresult;
    int32_t fragment_embedded_roots_hresult;
    int32_t fragment_set_focus_hresult;
    int32_t fragment_root_hresult;
    int32_t root_from_point_hresult;
    int32_t root_get_focus_hresult;
    int32_t invoke_provider_invoke_hresult;
    int32_t toggle_provider_toggle_hresult;
    int32_t toggle_provider_get_state_hresult;
    int32_t expand_collapse_provider_expand_hresult;
    int32_t expand_collapse_provider_collapse_hresult;
    int32_t expand_collapse_provider_get_state_hresult;
    int32_t scroll_item_provider_scroll_into_view_hresult;
    int32_t selection_item_provider_select_hresult;
    int32_t selection_item_provider_add_to_selection_hresult;
    int32_t selection_item_provider_remove_from_selection_hresult;
    int32_t selection_item_provider_get_is_selected_hresult;
    int32_t selection_item_provider_get_selection_container_hresult;
    int32_t range_value_provider_set_value_hresult;
    int32_t range_value_provider_get_value_hresult;
    int32_t range_value_provider_get_is_read_only_hresult;
    int32_t range_value_provider_get_maximum_hresult;
    int32_t range_value_provider_get_minimum_hresult;
    int32_t range_value_provider_get_large_change_hresult;
    int32_t range_value_provider_get_small_change_hresult;
    int32_t window_provider_close_hresult;
    int32_t window_provider_get_can_maximize_hresult;
    int32_t window_provider_get_can_minimize_hresult;
    int32_t window_provider_get_is_modal_hresult;
    int32_t window_provider_get_visual_state_hresult;
    int32_t window_provider_get_interaction_state_hresult;
    int32_t advise_events_advise_hresult;
    int32_t advise_events_unadvise_hresult;
};

#if defined(_WIN32)
static const wchar_t a11y_uia_probe_class_name[] =
    L"A11yKitUiaHostWindowProbe";
static const wchar_t a11y_uia_minimal_provider_probe_class_name[] =
    L"A11yKitUiaMinimalProviderHostWindowProbe";
static const wchar_t a11y_uia_callback_provider_probe_class_name[] =
    L"A11yKitUiaCallbackProviderHostWindowProbe";

struct a11y_uia_minimal_provider {
    const IRawElementProviderSimpleVtbl *lpVtbl;
    volatile LONG refs;
    HWND host_hwnd;
    struct a11y_uia_minimal_provider_host_window_probe *report;
};

struct a11y_uia_minimal_provider_window_context {
    struct a11y_uia_minimal_provider_host_window_probe *report;
    IRawElementProviderSimple *provider;
};

struct a11y_uia_callback_provider {
    const IRawElementProviderSimpleVtbl *lpVtbl;
    struct a11y_uia_callback_provider_fragment_iface *fragment_iface;
    struct a11y_uia_callback_provider_fragment_root_iface *fragment_root_iface;
    struct a11y_uia_callback_provider_invoke_iface *invoke_iface;
    struct a11y_uia_callback_provider_toggle_iface *toggle_iface;
    struct a11y_uia_callback_provider_expand_collapse_iface
        *expand_collapse_iface;
    struct a11y_uia_callback_provider_scroll_item_iface *scroll_item_iface;
    struct a11y_uia_callback_provider_selection_item_iface
        *selection_item_iface;
    struct a11y_uia_callback_provider_range_value_iface *range_value_iface;
    struct a11y_uia_callback_provider_window_iface *window_iface;
    struct a11y_uia_callback_provider_advise_events_iface
        *advise_events_iface;
    volatile LONG refs;
    HWND host_hwnd;
    uint64_t session;
    uint64_t provider;
    uint64_t object_token;
    uint32_t provider_options_method;
    uint32_t pattern_provider_method;
    uint32_t property_value_method;
    uint32_t host_raw_element_provider_method;
    uint32_t fragment_navigate_method;
    uint32_t fragment_runtime_id_method;
    uint32_t fragment_bounding_rectangle_method;
    uint32_t fragment_embedded_roots_method;
    uint32_t fragment_set_focus_method;
    uint32_t fragment_root_method;
    uint32_t root_from_point_method;
    uint32_t root_get_focus_method;
    uint32_t invoke_provider_invoke_method;
    uint32_t toggle_provider_toggle_method;
    uint32_t expand_collapse_provider_expand_method;
    uint32_t expand_collapse_provider_collapse_method;
    uint32_t scroll_item_provider_scroll_into_view_method;
    uint32_t selection_item_provider_select_method;
    uint32_t selection_item_provider_add_to_selection_method;
    uint32_t selection_item_provider_remove_from_selection_method;
    uint32_t selection_item_provider_get_is_selected_method;
    uint32_t selection_item_provider_get_selection_container_method;
    uint32_t range_value_provider_set_value_method;
    uint32_t range_value_provider_get_value_method;
    uint32_t range_value_provider_get_is_read_only_method;
    uint32_t range_value_provider_get_maximum_method;
    uint32_t range_value_provider_get_minimum_method;
    uint32_t range_value_provider_get_large_change_method;
    uint32_t range_value_provider_get_small_change_method;
    uint32_t window_provider_close_method;
    uint32_t window_provider_get_can_maximize_method;
    uint32_t window_provider_get_can_minimize_method;
    uint32_t window_provider_get_is_modal_method;
    uint32_t window_provider_get_visual_state_method;
    uint32_t window_provider_get_interaction_state_method;
    uint32_t advise_events_advise_method;
    uint32_t advise_events_unadvise_method;
    a11y_uia_callback callback;
    a11y_uia_frame_callback frame_callback;
    a11y_uia_value_callback value_callback;
    a11y_uia_uint32_array_callback uint32_array_callback;
    a11y_uia_rectangle_callback rectangle_callback;
    a11y_uia_boolean_callback boolean_callback;
    a11y_uia_pattern_callback pattern_callback;
    a11y_uia_state_callback state_callback;
    a11y_uia_range_value_callback range_value_callback;
    a11y_uia_range_value_query_callback range_value_query_callback;
    a11y_uia_window_query_callback window_query_callback;
    void *callback_context;
    struct a11y_uia_callback_provider_host_window_probe *report;
};

struct a11y_uia_callback_provider_fragment_iface {
    const IRawElementProviderFragmentVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_fragment_root_iface {
    const IRawElementProviderFragmentRootVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_invoke_iface {
    const IInvokeProviderVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_toggle_iface {
    const IToggleProviderVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_expand_collapse_iface {
    const IExpandCollapseProviderVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_scroll_item_iface {
    const IScrollItemProviderVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_selection_item_iface {
    const ISelectionItemProviderVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_range_value_iface {
    const IRangeValueProviderVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_window_iface {
    const IWindowProviderVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_advise_events_iface {
    const IRawElementProviderAdviseEventsVtbl *lpVtbl;
    struct a11y_uia_callback_provider *owner;
};

struct a11y_uia_callback_provider_window_context {
    struct a11y_uia_callback_provider_host_window_probe *report;
    IRawElementProviderSimple *provider;
};

#if defined(_WIN32)
struct a11y_uia_live_callback_provider_host {
    HWND hwnd;
    struct a11y_uia_callback_provider *provider;
    struct a11y_uia_callback_provider_window_context *context;
    uint32_t initialized_here;
    struct a11y_uia_callback_provider_host_window_probe report;
};
#endif

static struct a11y_uia_callback_provider *
a11y_uia_callback_invoke_owner(IInvokeProvider *self);
static struct a11y_uia_callback_provider *
a11y_uia_callback_toggle_owner(IToggleProvider *self);
static struct a11y_uia_callback_provider *
a11y_uia_callback_expand_collapse_owner(IExpandCollapseProvider *self);
static struct a11y_uia_callback_provider *
a11y_uia_callback_scroll_item_owner(IScrollItemProvider *self);
static struct a11y_uia_callback_provider *
a11y_uia_callback_selection_item_owner(ISelectionItemProvider *self);
static struct a11y_uia_callback_provider *
a11y_uia_callback_range_value_owner(IRangeValueProvider *self);
static struct a11y_uia_callback_provider *
a11y_uia_callback_window_owner(IWindowProvider *self);
static struct a11y_uia_callback_provider *
a11y_uia_callback_advise_events_owner(
    IRawElementProviderAdviseEvents *self);

static HRESULT STDMETHODCALLTYPE a11y_uia_minimal_provider_query_interface(
    IRawElementProviderSimple *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_minimal_provider *provider;

    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    provider = (struct a11y_uia_minimal_provider *)self;
    if (provider != 0 && provider->report != 0) {
        provider->report->provider_query_interface_called = 1;
    }

    if (IsEqualIID(iid, &IID_IUnknown) ||
        IsEqualIID(iid, &IID_IRawElementProviderSimple)) {
        *object = self;
        IRawElementProviderSimple_AddRef(self);
        return S_OK;
    }

    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_minimal_provider_add_ref(
    IRawElementProviderSimple *self) {
    struct a11y_uia_minimal_provider *provider =
        (struct a11y_uia_minimal_provider *)self;
    LONG refs;

    if (provider == 0) {
        return 0;
    }
    if (provider->report != 0) {
        provider->report->provider_add_ref_called = 1;
    }
    refs = InterlockedIncrement(&provider->refs);
    if (provider->report != 0) {
        provider->report->provider_final_ref_count = (uint32_t)refs;
    }
    return (ULONG)refs;
}

static ULONG STDMETHODCALLTYPE a11y_uia_minimal_provider_release(
    IRawElementProviderSimple *self) {
    struct a11y_uia_minimal_provider *provider =
        (struct a11y_uia_minimal_provider *)self;
    LONG refs;

    if (provider == 0) {
        return 0;
    }
    if (provider->report != 0) {
        provider->report->provider_release_called = 1;
    }
    refs = InterlockedDecrement(&provider->refs);
    if (provider->report != 0) {
        provider->report->provider_final_ref_count = (uint32_t)refs;
    }
    if (refs == 0) {
        free(provider);
    }
    return (ULONG)refs;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_minimal_provider_get_options(
    IRawElementProviderSimple *self,
    enum ProviderOptions *result) {
    struct a11y_uia_minimal_provider *provider =
        (struct a11y_uia_minimal_provider *)self;

    if (provider != 0 && provider->report != 0) {
        provider->report->provider_options_called = 1;
    }
    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = ProviderOptions_ServerSideProvider;
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_minimal_provider_get_pattern(
    IRawElementProviderSimple *self,
    PATTERNID pattern_id,
    IUnknown **result) {
    (void)self;
    (void)pattern_id;
    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_minimal_provider_get_property(
    IRawElementProviderSimple *self,
    PROPERTYID property_id,
    VARIANT *result) {
    (void)self;
    (void)property_id;
    if (result == 0) {
        return E_INVALIDARG;
    }
    VariantInit(result);
    result->vt = VT_EMPTY;
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_minimal_provider_get_host(
    IRawElementProviderSimple *self,
    IRawElementProviderSimple **result) {
    (void)self;
    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    return S_OK;
}

static const IRawElementProviderSimpleVtbl a11y_uia_minimal_provider_vtbl = {
    a11y_uia_minimal_provider_query_interface,
    a11y_uia_minimal_provider_add_ref,
    a11y_uia_minimal_provider_release,
    a11y_uia_minimal_provider_get_options,
    a11y_uia_minimal_provider_get_pattern,
    a11y_uia_minimal_provider_get_property,
    a11y_uia_minimal_provider_get_host
};

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_provider_query_interface(
    IRawElementProviderSimple *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider;

    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    provider = (struct a11y_uia_callback_provider *)self;
    if (provider != 0 && provider->report != 0) {
        provider->report->provider_query_interface_called = 1;
    }

    if (IsEqualIID(iid, &IID_IUnknown) ||
        IsEqualIID(iid, &IID_IRawElementProviderSimple)) {
        *object = self;
        IRawElementProviderSimple_AddRef(self);
        return S_OK;
    }

    if (IsEqualIID(iid, &IID_IRawElementProviderFragment)
        && provider != 0 && provider->fragment_iface != 0) {
        *object = provider->fragment_iface;
        if (provider->report != 0) {
            provider->report->fragment_query_interface_called = 1;
            provider->report->fragment_query_interface_succeeded = 1;
        }
        IRawElementProviderSimple_AddRef(self);
        return S_OK;
    }

    if (IsEqualIID(iid, &IID_IRawElementProviderFragmentRoot)
        && provider != 0 && provider->fragment_root_iface != 0) {
        *object = provider->fragment_root_iface;
        if (provider->report != 0) {
            provider->report->fragment_root_query_interface_called = 1;
            provider->report->fragment_root_query_interface_succeeded = 1;
        }
        IRawElementProviderSimple_AddRef(self);
        return S_OK;
    }

    if (IsEqualIID(iid, &IID_IRawElementProviderAdviseEvents)
        && provider != 0 && provider->advise_events_iface != 0) {
        *object = provider->advise_events_iface;
        IRawElementProviderSimple_AddRef(self);
        return S_OK;
    }

    if (IsEqualIID(iid, &IID_IWindowProvider)
        && provider != 0 && provider->window_iface != 0) {
        *object = provider->window_iface;
        IRawElementProviderSimple_AddRef(self);
        return S_OK;
    }

    if (IsEqualIID(iid, &IID_IRangeValueProvider)
        && provider != 0 && provider->range_value_iface != 0) {
        *object = provider->range_value_iface;
        IRawElementProviderSimple_AddRef(self);
        return S_OK;
    }

    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_provider_add_ref(
    IRawElementProviderSimple *self) {
    struct a11y_uia_callback_provider *provider =
        (struct a11y_uia_callback_provider *)self;
    LONG refs;

    if (provider == 0) {
        return 0;
    }
    if (provider->report != 0) {
        provider->report->provider_add_ref_called = 1;
    }
    refs = InterlockedIncrement(&provider->refs);
    if (provider->report != 0) {
        provider->report->provider_final_ref_count = (uint32_t)refs;
    }
    return (ULONG)refs;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_provider_release(
    IRawElementProviderSimple *self) {
    struct a11y_uia_callback_provider *provider =
        (struct a11y_uia_callback_provider *)self;
    LONG refs;

    if (provider == 0) {
        return 0;
    }
    if (provider->report != 0) {
        provider->report->provider_release_called = 1;
    }
    refs = InterlockedDecrement(&provider->refs);
    if (provider->report != 0) {
        provider->report->provider_final_ref_count = (uint32_t)refs;
    }
    if (refs == 0) {
        free(provider->fragment_iface);
        free(provider->fragment_root_iface);
        free(provider->invoke_iface);
        free(provider->toggle_iface);
        free(provider->expand_collapse_iface);
        free(provider->scroll_item_iface);
        free(provider->selection_item_iface);
        free(provider->range_value_iface);
        free(provider->window_iface);
        free(provider->advise_events_iface);
        free(provider);
    }
    return (ULONG)refs;
}

static HRESULT a11y_uia_callback_provider_dispatch_with_point(
    struct a11y_uia_callback_provider *provider,
    uint32_t method,
    uint32_t interface_code,
    uint32_t direction_code,
    int64_t point_x,
    int64_t point_y,
    uint32_t *hresult_record,
    uint32_t *called,
    uint32_t *callback_called,
    uint32_t *callback_succeeded) {
    uint32_t callback_result;
    uint64_t frame[8];

    if (called != 0) {
        *called = 1;
    }
    if (provider == 0 || method == 0) {
        return E_FAIL;
    }
    if (callback_called != 0) {
        *callback_called = 1;
    }

    if (provider->frame_callback != 0) {
        frame[0] = provider->session;
        frame[1] = provider->provider;
        frame[2] = provider->object_token;
        frame[3] = interface_code;
        frame[4] = method;
        frame[5] = direction_code;
        frame[6] = (uint64_t)point_x;
        frame[7] = (uint64_t)point_y;
        callback_result =
            provider->frame_callback(frame, provider->callback_context);
        if (provider->report != 0) {
            provider->report->full_frame_callback_called = 1;
            provider->report->full_frame_callback_succeeded =
                (callback_result == 0);
            provider->report->full_frame_session = frame[0];
            provider->report->full_frame_provider = frame[1];
            provider->report->full_frame_object_token = frame[2];
            provider->report->full_frame_interface = frame[3];
            provider->report->full_frame_method = frame[4];
            provider->report->full_frame_direction = frame[5];
            provider->report->full_frame_point_x = frame[6];
            provider->report->full_frame_point_y = frame[7];
            provider->report->full_frame_hresult = callback_result;
            if (interface_code == 2) {
                provider->report->full_frame_simple_count += 1;
            } else if (interface_code == 3) {
                provider->report->full_frame_fragment_count += 1;
            } else if (interface_code == 4) {
                provider->report->full_frame_root_count += 1;
            } else if (interface_code == 5) {
                provider->report->full_frame_advise_events_count += 1;
            }
        }
    } else if (provider->callback != 0) {
        callback_result = provider->callback(provider->session,
                                             provider->provider,
                                             method,
                                             provider->callback_context);
    } else {
        return E_FAIL;
    }

    if (hresult_record != 0) {
        *hresult_record = callback_result;
    }
    if (callback_succeeded != 0) {
        *callback_succeeded = (callback_result == 0);
    }
    return (HRESULT)callback_result;
}

static HRESULT a11y_uia_callback_provider_dispatch(
    struct a11y_uia_callback_provider *provider,
    uint32_t method,
    uint32_t interface_code,
    uint32_t direction_code,
    uint32_t *hresult_record,
    uint32_t *called,
    uint32_t *callback_called,
    uint32_t *callback_succeeded) {
    return a11y_uia_callback_provider_dispatch_with_point(
        provider,
        method,
        interface_code,
        direction_code,
        0,
        0,
        hresult_record,
        called,
        callback_called,
        callback_succeeded);
}

static int a11y_uia_callback_provider_pattern_supported(
    struct a11y_uia_callback_provider *provider,
    PATTERNID pattern_id) {
    uint64_t frame[6];
    uint32_t supported = 0;
    uint32_t callback_result;

    if (provider == 0 || provider->pattern_provider_method == 0) {
        return 0;
    }

    if (provider->pattern_callback == 0) {
        return 1;
    }

    frame[0] = provider->session;
    frame[1] = provider->provider;
    frame[2] = provider->object_token;
    frame[3] = 2;
    frame[4] = provider->pattern_provider_method;
    frame[5] = 0;
    if (provider->report != 0) {
        provider->report->pattern_provider_support_callback_called = 1;
    }
    callback_result =
        provider->pattern_callback(frame,
                                   (uint32_t)pattern_id,
                                   &supported,
                                   provider->callback_context);
    if (provider->report != 0) {
        provider->report->pattern_provider_support_callback_succeeded =
            (callback_result == 0);
    }
    return callback_result == 0 && supported != 0;
}

static HRESULT a11y_uia_callback_provider_state(
    struct a11y_uia_callback_provider *provider,
    uint32_t native_state_kind,
    uint32_t *state,
    uint32_t *hresult_record,
    uint32_t *called,
    uint32_t *callback_called,
    uint32_t *callback_succeeded) {
    uint64_t frame[6];
    uint32_t callback_result;

    if (called != 0) {
        *called = 1;
    }
    if (state == 0) {
        return E_INVALIDARG;
    }
    *state = 0;
    if (provider == 0 || provider->state_callback == 0) {
        return E_FAIL;
    }
    if (callback_called != 0) {
        *callback_called = 1;
    }

    frame[0] = provider->session;
    frame[1] = provider->provider;
    frame[2] = provider->object_token;
    frame[3] = 2;
    frame[4] = provider->property_value_method;
    frame[5] = 0;
    callback_result =
        provider->state_callback(frame,
                                 native_state_kind,
                                 state,
                                 provider->callback_context);
    if (hresult_record != 0) {
        *hresult_record = callback_result;
    }
    if (callback_succeeded != 0) {
        *callback_succeeded = (callback_result == 0);
    }
    return (HRESULT)callback_result;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_provider_get_options(
    IRawElementProviderSimple *self,
    enum ProviderOptions *result) {
    struct a11y_uia_callback_provider *provider =
        (struct a11y_uia_callback_provider *)self;

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = ProviderOptions_ServerSideProvider;
    if (provider->report != 0) {
        provider->report->options_callback_session = provider->session;
        provider->report->options_callback_provider = provider->provider;
        provider->report->options_callback_method =
            provider->provider_options_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->provider_options_method : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->options_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->provider_options_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->provider_options_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->provider_options_callback_succeeded : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_provider_get_pattern(
    IRawElementProviderSimple *self,
    PATTERNID pattern_id,
    IUnknown **result) {
    struct a11y_uia_callback_provider *provider =
        (struct a11y_uia_callback_provider *)self;
    HRESULT hr;

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider->report != 0) {
        provider->report->pattern_callback_session = provider->session;
        provider->report->pattern_callback_provider = provider->provider;
        provider->report->pattern_callback_method =
            provider->pattern_provider_method;
    }
    hr = a11y_uia_callback_provider_dispatch(
        provider,
        provider->pattern_provider_method,
        2,
        0,
        provider->report != 0 ? &provider->report->pattern_callback_hresult : 0,
        provider->report != 0 ? &provider->report->pattern_provider_called : 0,
        provider->report != 0 ? &provider->report->pattern_provider_callback_called : 0,
        provider->report != 0 ? &provider->report->pattern_provider_callback_succeeded : 0);
    if (SUCCEEDED(hr)
        && a11y_uia_callback_provider_pattern_supported(provider, pattern_id)
        && pattern_id == UIA_InvokePatternId &&
        provider != 0 && provider->invoke_iface != 0) {
        *result = (IUnknown *)provider->invoke_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report->pattern_provider_returned_invoke = 1;
        }
    } else if (SUCCEEDED(hr)
               && a11y_uia_callback_provider_pattern_supported(provider,
                                                               pattern_id)
               && pattern_id == UIA_TogglePatternId &&
               provider != 0 && provider->toggle_iface != 0) {
        *result = (IUnknown *)provider->toggle_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report->pattern_provider_returned_toggle = 1;
        }
    } else if (SUCCEEDED(hr)
               && a11y_uia_callback_provider_pattern_supported(provider,
                                                               pattern_id)
               && pattern_id == UIA_ExpandCollapsePatternId &&
               provider != 0 && provider->expand_collapse_iface != 0) {
        *result = (IUnknown *)provider->expand_collapse_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report->pattern_provider_returned_expand_collapse = 1;
        }
    } else if (SUCCEEDED(hr)
               && a11y_uia_callback_provider_pattern_supported(provider,
                                                               pattern_id)
               && pattern_id == UIA_ScrollItemPatternId &&
               provider != 0 && provider->scroll_item_iface != 0) {
        *result = (IUnknown *)provider->scroll_item_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report->pattern_provider_returned_scroll_item = 1;
        }
    } else if (SUCCEEDED(hr)
               && a11y_uia_callback_provider_pattern_supported(provider,
                                                               pattern_id)
               && pattern_id == UIA_SelectionItemPatternId &&
               provider != 0 && provider->selection_item_iface != 0) {
        *result = (IUnknown *)provider->selection_item_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report->pattern_provider_returned_selection_item = 1;
        }
    } else if (SUCCEEDED(hr)
               && a11y_uia_callback_provider_pattern_supported(provider,
                                                               pattern_id)
               && pattern_id == UIA_WindowPatternId &&
               provider != 0 && provider->window_iface != 0) {
        *result = (IUnknown *)provider->window_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report->pattern_provider_returned_window = 1;
        }
    } else if (SUCCEEDED(hr)
               && a11y_uia_callback_provider_pattern_supported(provider,
                                                               pattern_id)
               && pattern_id == UIA_RangeValuePatternId &&
               provider != 0 && provider->range_value_iface != 0) {
        *result = (IUnknown *)provider->range_value_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report->pattern_provider_returned_range_value = 1;
        }
    }
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_provider_get_property(
    IRawElementProviderSimple *self,
    PROPERTYID property_id,
    VARIANT *result) {
    struct a11y_uia_callback_provider *provider =
        (struct a11y_uia_callback_provider *)self;
    HRESULT hr;
    uint64_t frame[6];
    uint32_t value_kind = 0;
    uint32_t utf8_used = 0;
    char utf8_buffer[4096];

    if (result == 0) {
        return E_INVALIDARG;
    }
    VariantInit(result);
    result->vt = VT_EMPTY;
    if (provider->report != 0) {
        provider->report->property_callback_session = provider->session;
        provider->report->property_callback_provider = provider->provider;
        provider->report->property_callback_method =
            provider->property_value_method;
    }
    hr = a11y_uia_callback_provider_dispatch(
        provider,
        provider->property_value_method,
        2,
        0,
        provider->report != 0 ? &provider->report->property_callback_hresult : 0,
        provider->report != 0 ? &provider->report->property_value_called : 0,
        provider->report != 0 ? &provider->report->property_value_callback_called : 0,
        provider->report != 0 ? &provider->report->property_value_callback_succeeded : 0);
    if (SUCCEEDED(hr) && provider != 0 &&
        property_id == UIA_BoundingRectanglePropertyId &&
        provider->rectangle_callback != 0) {
        double left = 0.0;
        double top = 0.0;
        double width = 0.0;
        double height = 0.0;
        SAFEARRAY *array_value = 0;
        double *items = 0;
        frame[0] = provider->session;
        frame[1] = provider->provider;
        frame[2] = provider->object_token;
        frame[3] = 2;
        frame[4] = provider->fragment_bounding_rectangle_method;
        frame[5] = 0;
        hr = (HRESULT)provider->rectangle_callback(
            frame, &left, &top, &width, &height, provider->callback_context);
        if (FAILED(hr)) {
            return hr;
        }
        array_value = SafeArrayCreateVector(VT_R8, 0, 4);
        if (array_value == 0) {
            return E_OUTOFMEMORY;
        }
        hr = SafeArrayAccessData(array_value, (void **)&items);
        if (FAILED(hr)) {
            SafeArrayDestroy(array_value);
            return hr;
        }
        items[0] = left;
        items[1] = top;
        items[2] = width;
        items[3] = height;
        hr = SafeArrayUnaccessData(array_value);
        if (FAILED(hr)) {
            SafeArrayDestroy(array_value);
            return hr;
        }
        result->vt = VT_ARRAY | VT_R8;
        result->parray = array_value;
        return S_OK;
    }
    if (SUCCEEDED(hr) && provider != 0 && provider->value_callback != 0) {
        memset(utf8_buffer, 0, sizeof(utf8_buffer));
        frame[0] = provider->session;
        frame[1] = provider->provider;
        frame[2] = provider->object_token;
        frame[3] = 2;
        frame[4] = provider->property_value_method;
        frame[5] = 0;
        hr = (HRESULT)provider->value_callback(
            frame,
            (uint32_t)property_id,
            &value_kind,
            utf8_buffer,
            (uint32_t)sizeof(utf8_buffer),
            &utf8_used,
            provider->callback_context);
        if (SUCCEEDED(hr) && utf8_used > sizeof(utf8_buffer)) {
            return E_FAIL;
        }
        if (SUCCEEDED(hr) && value_kind == 1) {
            if (utf8_used > (uint32_t)INT_MAX) {
                return E_FAIL;
            }
            int wide_units = MultiByteToWideChar(
                CP_UTF8, MB_ERR_INVALID_CHARS, utf8_buffer,
                (int)utf8_used, 0, 0);
            if (utf8_used != 0 && wide_units == 0) {
                return E_FAIL;
            }
            result->vt = VT_BSTR;
            result->bstrVal = SysAllocStringLen(0, (UINT)wide_units);
            if (result->bstrVal == 0 && wide_units != 0) {
                result->vt = VT_EMPTY;
                return E_OUTOFMEMORY;
            }
            if (wide_units != 0) {
                if (MultiByteToWideChar(
                        CP_UTF8, MB_ERR_INVALID_CHARS, utf8_buffer,
                        (int)utf8_used, result->bstrVal, wide_units) !=
                    wide_units) {
                    SysFreeString(result->bstrVal);
                    result->bstrVal = 0;
                    result->vt = VT_EMPTY;
                    return E_FAIL;
                }
            }
        } else if (SUCCEEDED(hr) && value_kind == 3) {
            result->vt = VT_I4;
            result->lVal = (LONG)utf8_used;
        } else if (SUCCEEDED(hr) && value_kind == 4) {
            result->vt = VT_BOOL;
            result->boolVal = utf8_used != 0 ? VARIANT_TRUE : VARIANT_FALSE;
        } else if (SUCCEEDED(hr) && value_kind == 5) {
            result->vt = VT_EMPTY;
        } else if (SUCCEEDED(hr) && value_kind == 6) {
            result->vt = VT_EMPTY;
        }
    }
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_provider_get_host(
    IRawElementProviderSimple *self,
    IRawElementProviderSimple **result) {
    struct a11y_uia_callback_provider *provider =
        (struct a11y_uia_callback_provider *)self;
    uint32_t callback_result;

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider->report != 0) {
        provider->report->host_callback_session = provider->session;
        provider->report->host_callback_provider = provider->provider;
        provider->report->host_callback_method =
            provider->host_raw_element_provider_method;
    }
    callback_result = (uint32_t)a11y_uia_callback_provider_dispatch(
        provider,
        provider->host_raw_element_provider_method,
        2,
        0,
        provider->report != 0 ? &provider->report->host_callback_hresult : 0,
        provider->report != 0 ? &provider->report->host_raw_element_provider_called : 0,
        provider->report != 0 ? &provider->report->host_raw_element_provider_callback_called : 0,
        provider->report != 0 ? &provider->report->host_raw_element_provider_callback_succeeded : 0);
    if (SUCCEEDED((HRESULT)callback_result) && provider->host_hwnd != 0) {
        HRESULT host_hr = UiaHostProviderFromHwnd(provider->host_hwnd, result);
        if (SUCCEEDED(host_hr) && result != 0 && *result != 0 &&
            provider->report != 0) {
            provider->report->host_raw_element_provider_returned_host = 1;
        }
        return host_hr;
    }
    return (HRESULT)callback_result;
}

static const IRawElementProviderSimpleVtbl a11y_uia_callback_provider_vtbl = {
    a11y_uia_callback_provider_query_interface,
    a11y_uia_callback_provider_add_ref,
    a11y_uia_callback_provider_release,
    a11y_uia_callback_provider_get_options,
    a11y_uia_callback_provider_get_pattern,
    a11y_uia_callback_provider_get_property,
    a11y_uia_callback_provider_get_host
};

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_invoke_query_interface(
    IInvokeProvider *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_invoke_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_IInvokeProvider)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_invoke_add_ref(
    IInvokeProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_invoke_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_invoke_release(
    IInvokeProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_invoke_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_invoke_invoke(
    IInvokeProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_invoke_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->invoke_provider_invoke_callback_method =
            provider->invoke_provider_invoke_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->invoke_provider_invoke_method : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->invoke_provider_invoke_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->invoke_provider_invoke_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->invoke_provider_invoke_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->invoke_provider_invoke_callback_succeeded : 0);
}

static const IInvokeProviderVtbl a11y_uia_callback_invoke_vtbl = {
    a11y_uia_callback_invoke_query_interface,
    a11y_uia_callback_invoke_add_ref,
    a11y_uia_callback_invoke_release,
    a11y_uia_callback_invoke_invoke
};

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_toggle_query_interface(
    IToggleProvider *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_toggle_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_IToggleProvider)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_toggle_add_ref(
    IToggleProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_toggle_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_toggle_release(
    IToggleProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_toggle_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_toggle_toggle(
    IToggleProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_toggle_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->toggle_provider_toggle_callback_method =
            provider->toggle_provider_toggle_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->toggle_provider_toggle_method : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_toggle_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_toggle_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_toggle_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_toggle_callback_succeeded : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_toggle_get_state(
    IToggleProvider *self,
    enum ToggleState *state) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_toggle_owner(self);
    uint32_t semantic_state = 0;
    HRESULT hr;

    if (state == 0) {
        return E_INVALIDARG;
    }
    *state = ToggleState_Off;
    hr = a11y_uia_callback_provider_state(
        provider,
        1,
        &semantic_state,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_get_state_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_get_state_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_get_state_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->toggle_provider_get_state_callback_succeeded
            : 0);
    if (SUCCEEDED(hr)) {
        if (semantic_state == 2) {
            *state = ToggleState_Indeterminate;
        } else if (semantic_state == 1) {
            *state = ToggleState_On;
        } else {
            *state = ToggleState_Off;
        }
        if (provider != 0 && provider->report != 0) {
            provider->report->toggle_provider_state = semantic_state;
        }
    }
    return hr;
}

static const IToggleProviderVtbl a11y_uia_callback_toggle_vtbl = {
    a11y_uia_callback_toggle_query_interface,
    a11y_uia_callback_toggle_add_ref,
    a11y_uia_callback_toggle_release,
    a11y_uia_callback_toggle_toggle,
    a11y_uia_callback_toggle_get_state
};

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_expand_collapse_query_interface(
    IExpandCollapseProvider *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_expand_collapse_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_IExpandCollapseProvider)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_expand_collapse_add_ref(
    IExpandCollapseProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_expand_collapse_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_expand_collapse_release(
    IExpandCollapseProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_expand_collapse_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_expand_collapse_expand(
    IExpandCollapseProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_expand_collapse_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->expand_collapse_provider_expand_callback_method =
            provider->expand_collapse_provider_expand_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->expand_collapse_provider_expand_method : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->expand_collapse_provider_expand_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->expand_collapse_provider_expand_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_expand_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_expand_callback_succeeded
            : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_expand_collapse_collapse(
    IExpandCollapseProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_expand_collapse_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->expand_collapse_provider_collapse_callback_method =
            provider->expand_collapse_provider_collapse_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->expand_collapse_provider_collapse_method : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_collapse_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->expand_collapse_provider_collapse_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_collapse_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_collapse_callback_succeeded
            : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_expand_collapse_get_state(
    IExpandCollapseProvider *self,
    enum ExpandCollapseState *state) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_expand_collapse_owner(self);
    uint32_t semantic_state = 0;
    HRESULT hr;

    if (state == 0) {
        return E_INVALIDARG;
    }
    *state = ExpandCollapseState_Collapsed;
    hr = a11y_uia_callback_provider_state(
        provider,
        2,
        &semantic_state,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_get_state_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->expand_collapse_provider_get_state_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_get_state_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->expand_collapse_provider_get_state_callback_succeeded
            : 0);
    if (SUCCEEDED(hr)) {
        *state = semantic_state != 0
            ? ExpandCollapseState_Expanded
            : ExpandCollapseState_Collapsed;
        if (provider != 0 && provider->report != 0) {
            provider->report->expand_collapse_provider_state =
                semantic_state;
        }
    }
    return hr;
}

static const IExpandCollapseProviderVtbl
a11y_uia_callback_expand_collapse_vtbl = {
    a11y_uia_callback_expand_collapse_query_interface,
    a11y_uia_callback_expand_collapse_add_ref,
    a11y_uia_callback_expand_collapse_release,
    a11y_uia_callback_expand_collapse_expand,
    a11y_uia_callback_expand_collapse_collapse,
    a11y_uia_callback_expand_collapse_get_state
};

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_scroll_item_query_interface(
    IScrollItemProvider *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_scroll_item_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_IScrollItemProvider)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_scroll_item_add_ref(
    IScrollItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_scroll_item_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_scroll_item_release(
    IScrollItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_scroll_item_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_scroll_item_scroll_into_view(
    IScrollItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_scroll_item_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->scroll_item_provider_scroll_into_view_callback_method =
            provider->scroll_item_provider_scroll_into_view_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0
            ? provider->scroll_item_provider_scroll_into_view_method
            : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->scroll_item_provider_scroll_into_view_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->scroll_item_provider_scroll_into_view_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->scroll_item_provider_scroll_into_view_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->scroll_item_provider_scroll_into_view_callback_succeeded
            : 0);
}

static const IScrollItemProviderVtbl a11y_uia_callback_scroll_item_vtbl = {
    a11y_uia_callback_scroll_item_query_interface,
    a11y_uia_callback_scroll_item_add_ref,
    a11y_uia_callback_scroll_item_release,
    a11y_uia_callback_scroll_item_scroll_into_view
};

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_selection_item_query_interface(
    ISelectionItemProvider *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_ISelectionItemProvider)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_selection_item_add_ref(
    ISelectionItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_selection_item_release(
    ISelectionItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_selection_item_select(
    ISelectionItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->selection_item_provider_select_callback_method =
            provider->selection_item_provider_select_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->selection_item_provider_select_method : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_select_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->selection_item_provider_select_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_select_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_select_callback_succeeded
            : 0);
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_selection_item_add_to_selection(
    ISelectionItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report
            ->selection_item_provider_add_to_selection_callback_method =
            provider->selection_item_provider_add_to_selection_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0
            ? provider->selection_item_provider_add_to_selection_method
            : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_add_to_selection_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_add_to_selection_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_add_to_selection_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_add_to_selection_callback_succeeded
            : 0);
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_selection_item_remove_from_selection(
    ISelectionItemProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report
            ->selection_item_provider_remove_from_selection_callback_method =
            provider->selection_item_provider_remove_from_selection_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0
            ? provider->selection_item_provider_remove_from_selection_method
            : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_remove_from_selection_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_remove_from_selection_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_remove_from_selection_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_remove_from_selection_callback_succeeded
            : 0);
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_selection_item_get_is_selected(
    ISelectionItemProvider *self,
    BOOL *selected) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);
    uint64_t frame[6];
    uint32_t value = 0;
    uint32_t callback_result;

    if (selected == 0) {
        return E_INVALIDARG;
    }
    *selected = FALSE;
    if (provider == 0 ||
        provider->selection_item_provider_get_is_selected_method == 0) {
        return E_FAIL;
    }
    if (provider->report != 0) {
        provider->report->selection_item_provider_get_is_selected_called = 1;
        provider->report
            ->selection_item_provider_get_is_selected_callback_method =
            provider->selection_item_provider_get_is_selected_method;
    }
    if (provider->boolean_callback == 0) {
        return E_FAIL;
    }

    frame[0] = provider->session;
    frame[1] = provider->provider;
    frame[2] = provider->object_token;
    frame[3] = 2;
    frame[4] = provider->selection_item_provider_get_is_selected_method;
    frame[5] = 0;
    if (provider->report != 0) {
        provider->report
            ->selection_item_provider_get_is_selected_callback_called = 1;
    }
    callback_result =
        provider->boolean_callback(frame, &value, provider->callback_context);
    if (provider->report != 0) {
        provider->report
            ->selection_item_provider_get_is_selected_callback_hresult =
            callback_result;
        provider->report
            ->selection_item_provider_get_is_selected_callback_succeeded =
            (callback_result == 0);
        provider->report->selection_item_provider_is_selected =
            (value != 0);
    }
    if (callback_result != 0) {
        return (HRESULT)callback_result;
    }
    *selected = value != 0 ? TRUE : FALSE;
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_selection_item_get_selection_container(
    ISelectionItemProvider *self,
    IRawElementProviderSimple **container) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_selection_item_owner(self);
    HRESULT hr;

    if (container == 0) {
        return E_INVALIDARG;
    }
    *container = 0;
    if (provider != 0 && provider->report != 0) {
        provider->report
            ->selection_item_provider_get_selection_container_callback_method =
            provider->selection_item_provider_get_selection_container_method;
    }
    hr = a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0
            ? provider->selection_item_provider_get_selection_container_method
            : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_get_selection_container_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_get_selection_container_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_get_selection_container_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report
                   ->selection_item_provider_get_selection_container_callback_succeeded
            : 0);
    if (SUCCEEDED(hr) && provider != 0) {
        *container = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        if (provider->report != 0) {
            provider->report
                ->selection_item_provider_returned_selection_container = 1;
        }
    }
    return hr;
}

static const ISelectionItemProviderVtbl
a11y_uia_callback_selection_item_vtbl = {
    a11y_uia_callback_selection_item_query_interface,
    a11y_uia_callback_selection_item_add_ref,
    a11y_uia_callback_selection_item_release,
    a11y_uia_callback_selection_item_select,
    a11y_uia_callback_selection_item_add_to_selection,
    a11y_uia_callback_selection_item_remove_from_selection,
    a11y_uia_callback_selection_item_get_is_selected,
    a11y_uia_callback_selection_item_get_selection_container
};

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_range_value_query_interface(
    IRangeValueProvider *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_IRangeValueProvider)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_range_value_add_ref(
    IRangeValueProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_range_value_release(
    IRangeValueProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_range_value_set_value(
    IRangeValueProvider *self,
    double value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    uint64_t frame[6];
    uint32_t callback_result;

    if (provider != 0 && provider->report != 0) {
        provider->report->range_value_provider_set_value_called = 1;
        provider->report->range_value_provider_set_value_callback_method =
            provider->range_value_provider_set_value_method;
    }
    if (provider == 0 || provider->range_value_provider_set_value_method == 0
        || provider->range_value_callback == 0) {
        return E_FAIL;
    }

    if (provider->report != 0) {
        provider->report->range_value_provider_set_value_callback_called = 1;
    }
    frame[0] = provider->session;
    frame[1] = provider->provider;
    frame[2] = provider->object_token;
    frame[3] = 2;
    frame[4] = provider->range_value_provider_set_value_method;
    frame[5] = 0;
    callback_result =
        provider->range_value_callback(frame,
                                       value,
                                       provider->callback_context);
    if (provider->report != 0) {
        provider->report->range_value_provider_set_value_callback_hresult =
            callback_result;
        provider->report->range_value_provider_set_value_callback_succeeded =
            (callback_result == 0);
        provider->report->full_frame_callback_called = 1;
        provider->report->full_frame_callback_succeeded =
            (callback_result == 0);
        provider->report->full_frame_simple_count += 1;
        provider->report->full_frame_session = frame[0];
        provider->report->full_frame_provider = frame[1];
        provider->report->full_frame_object_token = frame[2];
        provider->report->full_frame_interface = frame[3];
        provider->report->full_frame_method = frame[4];
        provider->report->full_frame_direction = frame[5];
        provider->report->full_frame_point_x = 0;
        provider->report->full_frame_point_y = 0;
        provider->report->full_frame_hresult = callback_result;
    }
    return (HRESULT)callback_result;
}

static HRESULT a11y_uia_callback_range_value_query(
    struct a11y_uia_callback_provider *provider,
    uint32_t method,
    double *numeric_value,
    BOOL *boolean_value,
    uint32_t *report_method,
    uint32_t *report_hresult,
    uint32_t *report_succeeded) {
    uint64_t frame[6];
    uint32_t boolean_result = 0;
    uint32_t callback_result;

    if (numeric_value != 0) {
        *numeric_value = 0.0;
    }
    if (boolean_value != 0) {
        *boolean_value = FALSE;
    }
    if (report_method != 0) {
        *report_method = method;
    }
    if (provider == 0 || method == 0
        || provider->range_value_query_callback == 0
        || numeric_value == 0 || boolean_value == 0) {
        return E_FAIL;
    }

    frame[0] = provider->session;
    frame[1] = provider->provider;
    frame[2] = provider->object_token;
    frame[3] = 2;
    frame[4] = method;
    frame[5] = 0;
    callback_result =
        provider->range_value_query_callback(frame,
                                            numeric_value,
                                            &boolean_result,
                                            provider->callback_context);
    *boolean_value = boolean_result != 0 ? TRUE : FALSE;
    if (report_hresult != 0) {
        *report_hresult = callback_result;
    }
    if (report_succeeded != 0) {
        *report_succeeded = (callback_result == 0);
    }
    if (provider->report != 0) {
        provider->report->full_frame_callback_called = 1;
        provider->report->full_frame_callback_succeeded =
            (callback_result == 0);
        provider->report->full_frame_simple_count += 1;
        provider->report->full_frame_session = frame[0];
        provider->report->full_frame_provider = frame[1];
        provider->report->full_frame_object_token = frame[2];
        provider->report->full_frame_interface = frame[3];
        provider->report->full_frame_method = frame[4];
        provider->report->full_frame_direction = frame[5];
        provider->report->full_frame_point_x = 0;
        provider->report->full_frame_point_y = 0;
        provider->report->full_frame_hresult = callback_result;
    }
    return (HRESULT)callback_result;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_range_value_get_value(
    IRangeValueProvider *self,
    double *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    BOOL ignored = FALSE;
    if (value == 0) {
        return E_INVALIDARG;
    }
    return a11y_uia_callback_range_value_query
      (provider,
       provider != 0 ? provider->range_value_provider_get_value_method : 0,
       value,
       &ignored,
       provider != 0 && provider->report != 0
          ? &provider->report->range_value_provider_get_value_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report->range_value_provider_get_value_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report->range_value_provider_get_value_callback_succeeded
          : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_range_value_get_read_only(
    IRangeValueProvider *self,
    BOOL *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    double ignored = 0.0;
    if (value == 0) {
        return E_INVALIDARG;
    }
    return a11y_uia_callback_range_value_query
      (provider,
       provider != 0
          ? provider->range_value_provider_get_is_read_only_method : 0,
       &ignored,
       value,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_is_read_only_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_is_read_only_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_is_read_only_callback_succeeded
          : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_range_value_get_maximum(
    IRangeValueProvider *self,
    double *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    BOOL ignored = FALSE;
    if (value == 0) {
        return E_INVALIDARG;
    }
    return a11y_uia_callback_range_value_query
      (provider,
       provider != 0 ? provider->range_value_provider_get_maximum_method : 0,
       value,
       &ignored,
       provider != 0 && provider->report != 0
          ? &provider->report->range_value_provider_get_maximum_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report->range_value_provider_get_maximum_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_maximum_callback_succeeded
          : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_range_value_get_minimum(
    IRangeValueProvider *self,
    double *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    BOOL ignored = FALSE;
    if (value == 0) {
        return E_INVALIDARG;
    }
    return a11y_uia_callback_range_value_query
      (provider,
       provider != 0 ? provider->range_value_provider_get_minimum_method : 0,
       value,
       &ignored,
       provider != 0 && provider->report != 0
          ? &provider->report->range_value_provider_get_minimum_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report->range_value_provider_get_minimum_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_minimum_callback_succeeded
          : 0);
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_range_value_get_large_change(
    IRangeValueProvider *self,
    double *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    BOOL ignored = FALSE;
    if (value == 0) {
        return E_INVALIDARG;
    }
    return a11y_uia_callback_range_value_query
      (provider,
       provider != 0
          ? provider->range_value_provider_get_large_change_method : 0,
       value,
       &ignored,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_large_change_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_large_change_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_large_change_callback_succeeded
          : 0);
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_range_value_get_small_change(
    IRangeValueProvider *self,
    double *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_range_value_owner(self);
    BOOL ignored = FALSE;
    if (value == 0) {
        return E_INVALIDARG;
    }
    return a11y_uia_callback_range_value_query
      (provider,
       provider != 0
          ? provider->range_value_provider_get_small_change_method : 0,
       value,
       &ignored,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_small_change_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_small_change_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->range_value_provider_get_small_change_callback_succeeded
          : 0);
}

static const IRangeValueProviderVtbl
a11y_uia_callback_range_value_vtbl = {
    a11y_uia_callback_range_value_query_interface,
    a11y_uia_callback_range_value_add_ref,
    a11y_uia_callback_range_value_release,
    a11y_uia_callback_range_value_set_value,
    a11y_uia_callback_range_value_get_value,
    a11y_uia_callback_range_value_get_read_only,
    a11y_uia_callback_range_value_get_maximum,
    a11y_uia_callback_range_value_get_minimum,
    a11y_uia_callback_range_value_get_large_change,
    a11y_uia_callback_range_value_get_small_change
};

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_window_query_interface(
    IWindowProvider *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_IWindowProvider)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_window_add_ref(
    IWindowProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_window_release(
    IWindowProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_window_set_visual_state(
    IWindowProvider *self,
    enum WindowVisualState state) {
    (void)self;
    (void)state;
    return UIA_E_INVALIDOPERATION;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_window_close(
    IWindowProvider *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->window_provider_close_callback_method =
            provider->window_provider_close_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->window_provider_close_method : 0,
        2,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->window_provider_close_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->window_provider_close_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->window_provider_close_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->window_provider_close_callback_succeeded
            : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_window_wait_for_input_idle(
    IWindowProvider *self,
    int milliseconds,
    BOOL *success) {
    (void)self;
    (void)milliseconds;
    if (success == 0) {
        return E_INVALIDARG;
    }
    *success = FALSE;
    return UIA_E_INVALIDOPERATION;
}

static HRESULT a11y_uia_callback_window_query(
    struct a11y_uia_callback_provider *provider,
    uint32_t method,
    uint32_t *value,
    uint32_t *report_method,
    uint32_t *report_hresult,
    uint32_t *report_succeeded) {
    uint64_t frame[6];
    uint32_t callback_result;

    if (value != 0) {
        *value = 0;
    }
    if (report_method != 0) {
        *report_method = method;
    }
    if (provider == 0 || method == 0 || value == 0
        || provider->window_query_callback == 0) {
        return E_FAIL;
    }

    frame[0] = provider->session;
    frame[1] = provider->provider;
    frame[2] = provider->object_token;
    frame[3] = 2;
    frame[4] = method;
    frame[5] = 0;
    callback_result =
        provider->window_query_callback(frame,
                                        value,
                                        provider->callback_context);
    if (report_hresult != 0) {
        *report_hresult = callback_result;
    }
    if (report_succeeded != 0) {
        *report_succeeded = (callback_result == 0);
    }
    if (provider->report != 0) {
        provider->report->full_frame_callback_called = 1;
        provider->report->full_frame_callback_succeeded =
            (callback_result == 0);
        provider->report->full_frame_simple_count += 1;
        provider->report->full_frame_session = frame[0];
        provider->report->full_frame_provider = frame[1];
        provider->report->full_frame_object_token = frame[2];
        provider->report->full_frame_interface = frame[3];
        provider->report->full_frame_method = frame[4];
        provider->report->full_frame_direction = frame[5];
        provider->report->full_frame_point_x = 0;
        provider->report->full_frame_point_y = 0;
        provider->report->full_frame_hresult = callback_result;
    }
    return (HRESULT)callback_result;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_window_get_can_maximize(
    IWindowProvider *self,
    BOOL *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    uint32_t raw_value = 0;
    HRESULT hr;
    if (value == 0) {
        return E_INVALIDARG;
    }
    hr = a11y_uia_callback_window_query
      (provider,
       provider != 0 ? provider->window_provider_get_can_maximize_method : 0,
       &raw_value,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_can_maximize_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_can_maximize_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_can_maximize_callback_succeeded
          : 0);
    *value = raw_value != 0 ? TRUE : FALSE;
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_window_get_can_minimize(
    IWindowProvider *self,
    BOOL *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    uint32_t raw_value = 0;
    HRESULT hr;
    if (value == 0) {
        return E_INVALIDARG;
    }
    hr = a11y_uia_callback_window_query
      (provider,
       provider != 0 ? provider->window_provider_get_can_minimize_method : 0,
       &raw_value,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_can_minimize_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_can_minimize_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_can_minimize_callback_succeeded
          : 0);
    *value = raw_value != 0 ? TRUE : FALSE;
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_window_get_is_modal(
    IWindowProvider *self,
    BOOL *value) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    uint32_t raw_value = 0;
    HRESULT hr;
    if (value == 0) {
        return E_INVALIDARG;
    }
    hr = a11y_uia_callback_window_query
      (provider,
       provider != 0 ? provider->window_provider_get_is_modal_method : 0,
       &raw_value,
       provider != 0 && provider->report != 0
          ? &provider->report->window_provider_get_is_modal_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report->window_provider_get_is_modal_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report->window_provider_get_is_modal_callback_succeeded
          : 0);
    *value = raw_value != 0 ? TRUE : FALSE;
    return hr;
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_window_get_window_visual_state(
    IWindowProvider *self,
    enum WindowVisualState *state) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    uint32_t raw_value = 0;
    HRESULT hr;
    if (state == 0) {
        return E_INVALIDARG;
    }
    hr = a11y_uia_callback_window_query
      (provider,
       provider != 0 ? provider->window_provider_get_visual_state_method : 0,
       &raw_value,
       provider != 0 && provider->report != 0
          ? &provider->report->window_provider_get_visual_state_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report->window_provider_get_visual_state_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_visual_state_callback_succeeded
          : 0);
    *state = (enum WindowVisualState)raw_value;
    return hr;
}

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_window_get_window_interaction_state(
    IWindowProvider *self,
    enum WindowInteractionState *state) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_window_owner(self);
    uint32_t raw_value = 0;
    HRESULT hr;
    if (state == 0) {
        return E_INVALIDARG;
    }
    hr = a11y_uia_callback_window_query
      (provider,
       provider != 0
          ? provider->window_provider_get_interaction_state_method : 0,
       &raw_value,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_interaction_state_callback_method
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_interaction_state_callback_hresult
          : 0,
       provider != 0 && provider->report != 0
          ? &provider->report
                ->window_provider_get_interaction_state_callback_succeeded
          : 0);
    *state = (enum WindowInteractionState)raw_value;
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_window_get_is_topmost(
    IWindowProvider *self,
    BOOL *value) {
    (void)self;
    if (value == 0) {
        return E_INVALIDARG;
    }
    *value = FALSE;
    return S_OK;
}

static const IWindowProviderVtbl a11y_uia_callback_window_vtbl = {
    a11y_uia_callback_window_query_interface,
    a11y_uia_callback_window_add_ref,
    a11y_uia_callback_window_release,
    a11y_uia_callback_window_set_visual_state,
    a11y_uia_callback_window_close,
    a11y_uia_callback_window_wait_for_input_idle,
    a11y_uia_callback_window_get_can_maximize,
    a11y_uia_callback_window_get_can_minimize,
    a11y_uia_callback_window_get_is_modal,
    a11y_uia_callback_window_get_window_visual_state,
    a11y_uia_callback_window_get_window_interaction_state,
    a11y_uia_callback_window_get_is_topmost
};

static HRESULT STDMETHODCALLTYPE
a11y_uia_callback_advise_events_query_interface(
    IRawElementProviderAdviseEvents *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_advise_events_owner(self);
    if (object == 0) {
        return E_INVALIDARG;
    }
    *object = 0;
    if (provider == 0) {
        return E_FAIL;
    }
    if (IsEqualIID(iid, &IID_IUnknown)) {
        *object = (IRawElementProviderSimple *)provider;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    if (IsEqualIID(iid, &IID_IRawElementProviderAdviseEvents)) {
        *object = self;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
        return S_OK;
    }
    return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_advise_events_add_ref(
    IRawElementProviderAdviseEvents *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_advise_events_owner(self);
    return a11y_uia_callback_provider_add_ref
      ((IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_advise_events_release(
    IRawElementProviderAdviseEvents *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_advise_events_owner(self);
    return a11y_uia_callback_provider_release
      ((IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_advise_events_added(
    IRawElementProviderAdviseEvents *self,
    EVENTID event_id,
    SAFEARRAY *property_ids) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_advise_events_owner(self);

    (void)event_id;
    (void)property_ids;
    if (provider != 0 && provider->report != 0) {
        provider->report->advise_events_advise_callback_method =
            provider->advise_events_advise_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->advise_events_advise_method : 0,
        5,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_advise_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_advise_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_advise_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_advise_callback_succeeded
            : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_advise_events_removed(
    IRawElementProviderAdviseEvents *self,
    EVENTID event_id,
    SAFEARRAY *property_ids) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_advise_events_owner(self);

    (void)event_id;
    (void)property_ids;
    if (provider != 0 && provider->report != 0) {
        provider->report->advise_events_unadvise_callback_method =
            provider->advise_events_unadvise_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->advise_events_unadvise_method : 0,
        5,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_unadvise_callback_hresult
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_unadvise_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_unadvise_callback_called
            : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->advise_events_unadvise_callback_succeeded
            : 0);
}

static const IRawElementProviderAdviseEventsVtbl
a11y_uia_callback_advise_events_vtbl = {
    a11y_uia_callback_advise_events_query_interface,
    a11y_uia_callback_advise_events_add_ref,
    a11y_uia_callback_advise_events_release,
    a11y_uia_callback_advise_events_added,
    a11y_uia_callback_advise_events_removed
};

static struct a11y_uia_callback_provider *
a11y_uia_callback_fragment_owner(IRawElementProviderFragment *self) {
    struct a11y_uia_callback_provider_fragment_iface *iface =
        (struct a11y_uia_callback_provider_fragment_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_fragment_root_owner(IRawElementProviderFragmentRoot *self) {
    struct a11y_uia_callback_provider_fragment_root_iface *iface =
        (struct a11y_uia_callback_provider_fragment_root_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_invoke_owner(IInvokeProvider *self) {
    struct a11y_uia_callback_provider_invoke_iface *iface =
        (struct a11y_uia_callback_provider_invoke_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_toggle_owner(IToggleProvider *self) {
    struct a11y_uia_callback_provider_toggle_iface *iface =
        (struct a11y_uia_callback_provider_toggle_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_expand_collapse_owner(IExpandCollapseProvider *self) {
    struct a11y_uia_callback_provider_expand_collapse_iface *iface =
        (struct a11y_uia_callback_provider_expand_collapse_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_scroll_item_owner(IScrollItemProvider *self) {
    struct a11y_uia_callback_provider_scroll_item_iface *iface =
        (struct a11y_uia_callback_provider_scroll_item_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_selection_item_owner(ISelectionItemProvider *self) {
    struct a11y_uia_callback_provider_selection_item_iface *iface =
        (struct a11y_uia_callback_provider_selection_item_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_range_value_owner(IRangeValueProvider *self) {
    struct a11y_uia_callback_provider_range_value_iface *iface =
        (struct a11y_uia_callback_provider_range_value_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_window_owner(IWindowProvider *self) {
    struct a11y_uia_callback_provider_window_iface *iface =
        (struct a11y_uia_callback_provider_window_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static struct a11y_uia_callback_provider *
a11y_uia_callback_advise_events_owner(
    IRawElementProviderAdviseEvents *self) {
    struct a11y_uia_callback_provider_advise_events_iface *iface =
        (struct a11y_uia_callback_provider_advise_events_iface *)self;
    return iface != 0 ? iface->owner : 0;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_query_interface(
    IRawElementProviderFragment *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);
    if (provider == 0) {
        return E_FAIL;
    }
    return a11y_uia_callback_provider_query_interface(
        (IRawElementProviderSimple *)provider, iid, object);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_fragment_add_ref(
    IRawElementProviderFragment *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);
    return a11y_uia_callback_provider_add_ref(
        (IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_fragment_release(
    IRawElementProviderFragment *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);
    return a11y_uia_callback_provider_release(
        (IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_navigate(
    IRawElementProviderFragment *self,
    enum NavigateDirection direction,
    IRawElementProviderFragment **result) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);

    (void)direction;
    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider != 0 && provider->report != 0) {
        provider->report->fragment_navigate_callback_method =
            provider->fragment_navigate_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->fragment_navigate_method : 0,
        3,
        direction == NavigateDirection_FirstChild ? 1u :
        direction == NavigateDirection_LastChild ? 2u :
        direction == NavigateDirection_NextSibling ? 3u :
        direction == NavigateDirection_PreviousSibling ? 4u : 0u,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_navigate_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_navigate_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_navigate_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_navigate_callback_succeeded : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_runtime_id(
    IRawElementProviderFragment *self,
    SAFEARRAY **result) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);
    HRESULT hr;
    uint64_t frame[6];
    uint32_t value_kind = 0;
    uint32_t items_used = 0;
    uint32_t items[8];

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider != 0 && provider->report != 0) {
        provider->report->fragment_runtime_id_callback_method =
            provider->fragment_runtime_id_method;
    }
    hr = a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->fragment_runtime_id_method : 0,
        3,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_runtime_id_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_runtime_id_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_runtime_id_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_runtime_id_callback_succeeded : 0);
    if (SUCCEEDED(hr) && provider != 0 &&
        provider->uint32_array_callback != 0) {
        LONG *array_data = 0;
        LONG index;

        memset(items, 0, sizeof(items));
        frame[0] = provider->session;
        frame[1] = provider->provider;
        frame[2] = provider->object_token;
        frame[3] = 3;
        frame[4] = provider->fragment_runtime_id_method;
        frame[5] = 0;
        hr = (HRESULT)provider->uint32_array_callback(
            frame,
            &value_kind,
            items,
            (uint32_t)(sizeof(items) / sizeof(items[0])),
            &items_used,
            provider->callback_context);
        if (FAILED(hr)) {
            return hr;
        }
        if (value_kind != 2 || items_used == 0 ||
            items_used > (uint32_t)(sizeof(items) / sizeof(items[0])) ||
            items_used > (uint32_t)LONG_MAX) {
            return E_FAIL;
        }
        *result = SafeArrayCreateVector(VT_I4, 0, (ULONG)items_used);
        if (*result == 0) {
            return E_OUTOFMEMORY;
        }
        hr = SafeArrayAccessData(*result, (void **)&array_data);
        if (FAILED(hr) || array_data == 0) {
            SafeArrayDestroy(*result);
            *result = 0;
            return FAILED(hr) ? hr : E_FAIL;
        }
        for (index = 0; index < (LONG)items_used; index++) {
            if (items[index] > (uint32_t)LONG_MAX) {
                SafeArrayUnaccessData(*result);
                SafeArrayDestroy(*result);
                *result = 0;
                return E_FAIL;
            }
            array_data[index] = (LONG)items[index];
        }
        hr = SafeArrayUnaccessData(*result);
        if (FAILED(hr)) {
            SafeArrayDestroy(*result);
            *result = 0;
            return hr;
        }
    }
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_bounding_rectangle(
    IRawElementProviderFragment *self,
    struct UiaRect *result) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);
    HRESULT hr;
    uint64_t frame[6];
    double left = 0.0;
    double top = 0.0;
    double width = 0.0;
    double height = 0.0;

    if (result == 0) {
        return E_INVALIDARG;
    }
    result->left = 0.0;
    result->top = 0.0;
    result->width = 0.0;
    result->height = 0.0;
    if (provider != 0 && provider->report != 0) {
        provider->report->fragment_bounding_rectangle_callback_method =
            provider->fragment_bounding_rectangle_method;
    }
    hr = a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->fragment_bounding_rectangle_method : 0,
        3,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_bounding_rectangle_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_bounding_rectangle_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_bounding_rectangle_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_bounding_rectangle_callback_succeeded : 0);
    if (SUCCEEDED(hr) && provider != 0 &&
        provider->rectangle_callback != 0) {
        frame[0] = provider->session;
        frame[1] = provider->provider;
        frame[2] = provider->object_token;
        frame[3] = 3;
        frame[4] = provider->fragment_bounding_rectangle_method;
        frame[5] = 0;
        hr = (HRESULT)provider->rectangle_callback(
            frame, &left, &top, &width, &height,
            provider->callback_context);
        if (SUCCEEDED(hr)) {
            result->left = left;
            result->top = top;
            result->width = width;
            result->height = height;
        }
    }
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_embedded_roots(
    IRawElementProviderFragment *self,
    SAFEARRAY **result) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider != 0 && provider->report != 0) {
        provider->report->fragment_embedded_roots_callback_method =
            provider->fragment_embedded_roots_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->fragment_embedded_roots_method : 0,
        3,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_embedded_roots_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_embedded_roots_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_embedded_roots_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_embedded_roots_callback_succeeded : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_set_focus(
    IRawElementProviderFragment *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);

    if (provider != 0 && provider->report != 0) {
        provider->report->fragment_set_focus_callback_method =
            provider->fragment_set_focus_method;
    }
    return a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->fragment_set_focus_method : 0,
        3,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_set_focus_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_set_focus_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_set_focus_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_set_focus_callback_succeeded : 0);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_root(
    IRawElementProviderFragment *self,
    IRawElementProviderFragmentRoot **result) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_owner(self);
    HRESULT hr;

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider != 0 && provider->report != 0) {
        provider->report->fragment_root_callback_method =
            provider->fragment_root_method;
    }
    hr = a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->fragment_root_method : 0,
        3,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_root_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_root_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_root_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->fragment_root_callback_succeeded : 0);
    if (SUCCEEDED(hr) && provider != 0 && provider->fragment_root_iface != 0) {
        *result = (IRawElementProviderFragmentRoot *)provider->fragment_root_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
    }
    return hr;
}

static const IRawElementProviderFragmentVtbl
a11y_uia_callback_fragment_vtbl = {
    a11y_uia_callback_fragment_query_interface,
    a11y_uia_callback_fragment_add_ref,
    a11y_uia_callback_fragment_release,
    a11y_uia_callback_fragment_navigate,
    a11y_uia_callback_fragment_runtime_id,
    a11y_uia_callback_fragment_bounding_rectangle,
    a11y_uia_callback_fragment_embedded_roots,
    a11y_uia_callback_fragment_set_focus,
    a11y_uia_callback_fragment_root
};

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_fragment_root_query_interface(
    IRawElementProviderFragmentRoot *self,
    REFIID iid,
    void **object) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_root_owner(self);
    if (provider == 0) {
        return E_FAIL;
    }
    return a11y_uia_callback_provider_query_interface(
        (IRawElementProviderSimple *)provider, iid, object);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_fragment_root_add_ref(
    IRawElementProviderFragmentRoot *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_root_owner(self);
    return a11y_uia_callback_provider_add_ref(
        (IRawElementProviderSimple *)provider);
}

static ULONG STDMETHODCALLTYPE a11y_uia_callback_fragment_root_release(
    IRawElementProviderFragmentRoot *self) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_root_owner(self);
    return a11y_uia_callback_provider_release(
        (IRawElementProviderSimple *)provider);
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_root_from_point(
    IRawElementProviderFragmentRoot *self,
    double x,
    double y,
    IRawElementProviderFragment **result) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_root_owner(self);
    HRESULT hr;

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider != 0 && provider->report != 0) {
        provider->report->root_from_point_callback_method =
            provider->root_from_point_method;
    }
    hr = a11y_uia_callback_provider_dispatch_with_point(
        provider,
        provider != 0 ? provider->root_from_point_method : 0,
        4,
        0,
        (int64_t)x,
        (int64_t)y,
        provider != 0 && provider->report != 0
            ? &provider->report->root_from_point_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->root_from_point_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->root_from_point_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->root_from_point_callback_succeeded : 0);
    if (SUCCEEDED(hr) && provider != 0 && provider->fragment_iface != 0) {
        *result = (IRawElementProviderFragment *)provider->fragment_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
    }
    return hr;
}

static HRESULT STDMETHODCALLTYPE a11y_uia_callback_root_get_focus(
    IRawElementProviderFragmentRoot *self,
    IRawElementProviderFragment **result) {
    struct a11y_uia_callback_provider *provider =
        a11y_uia_callback_fragment_root_owner(self);
    HRESULT hr;

    if (result == 0) {
        return E_INVALIDARG;
    }
    *result = 0;
    if (provider != 0 && provider->report != 0) {
        provider->report->root_get_focus_callback_method =
            provider->root_get_focus_method;
    }
    hr = a11y_uia_callback_provider_dispatch(
        provider,
        provider != 0 ? provider->root_get_focus_method : 0,
        4,
        0,
        provider != 0 && provider->report != 0
            ? &provider->report->root_get_focus_callback_hresult : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->root_get_focus_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->root_get_focus_callback_called : 0,
        provider != 0 && provider->report != 0
            ? &provider->report->root_get_focus_callback_succeeded : 0);
    if (SUCCEEDED(hr) && provider != 0 && provider->fragment_iface != 0) {
        *result = (IRawElementProviderFragment *)provider->fragment_iface;
        IRawElementProviderSimple_AddRef((IRawElementProviderSimple *)provider);
    }
    return hr;
}

static const IRawElementProviderFragmentRootVtbl
a11y_uia_callback_fragment_root_vtbl = {
    a11y_uia_callback_fragment_root_query_interface,
    a11y_uia_callback_fragment_root_add_ref,
    a11y_uia_callback_fragment_root_release,
    a11y_uia_callback_root_from_point,
    a11y_uia_callback_root_get_focus
};

static LRESULT CALLBACK a11y_uia_probe_window_proc(HWND hwnd,
                                                   UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
    struct a11y_uia_host_window_probe *report;

    report = (struct a11y_uia_host_window_probe *)
        GetWindowLongPtrW(hwnd, GWLP_USERDATA);

    if (message == WM_GETOBJECT) {
        if (report != 0) {
            report->wm_getobject_sent = 1;
            if (lparam == UiaRootObjectId) {
                LRESULT result;
                report->uia_root_object_id_matched = 1;
                report->return_raw_element_provider_called = 1;
                result = UiaReturnRawElementProvider(hwnd, wparam, lparam, 0);
                report->return_raw_element_provider_lresult = (int32_t)result;
                report->null_provider_returned_zero = (result == 0);
                return result;
            }
        }
    }

    return DefWindowProcW(hwnd, message, wparam, lparam);
}

static LRESULT CALLBACK a11y_uia_minimal_provider_probe_window_proc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
    struct a11y_uia_minimal_provider_window_context *context;

    context = (struct a11y_uia_minimal_provider_window_context *)
        GetWindowLongPtrW(hwnd, GWLP_USERDATA);

    if (message == WM_GETOBJECT) {
        if (context != 0 && context->report != 0) {
            context->report->wm_getobject_sent = 1;
            if (lparam == UiaRootObjectId) {
                LRESULT result;
                context->report->uia_root_object_id_matched = 1;
                context->report->return_raw_element_provider_called = 1;
                result = UiaReturnRawElementProvider
                    (hwnd, wparam, lparam, context->provider);
                context->report->return_raw_element_provider_lresult =
                    (int32_t)result;
                context->report->return_raw_element_provider_nonzero =
                    (result != 0);
                return result;
            }
        }
    }

    return DefWindowProcW(hwnd, message, wparam, lparam);
}

static LRESULT CALLBACK a11y_uia_callback_provider_probe_window_proc(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
    struct a11y_uia_callback_provider_window_context *context;

    context = (struct a11y_uia_callback_provider_window_context *)
        GetWindowLongPtrW(hwnd, GWLP_USERDATA);

    if (message == WM_GETOBJECT) {
        if (context != 0 && context->report != 0) {
            context->report->wm_getobject_sent = 1;
            if (lparam == UiaRootObjectId) {
                LRESULT result;
                context->report->uia_root_object_id_matched = 1;
                context->report->return_raw_element_provider_called = 1;
                result = UiaReturnRawElementProvider
                    (hwnd, wparam, lparam, context->provider);
                context->report->return_raw_element_provider_lresult =
                    (int32_t)result;
                context->report->return_raw_element_provider_nonzero =
                    (result != 0);
                return result;
            }
        }
    }

    return DefWindowProcW(hwnd, message, wparam, lparam);
}
#endif

uint32_t a11y_uia_query_interface(a11y_uia_callback callback,
                                  uint64_t session,
                                  uint64_t provider,
                                  uint32_t interface_id,
                                  void *context) {
    if (callback == 0) {
        return 0;
    }
    return callback(session, provider, interface_id, context);
}

uint32_t a11y_uia_add_ref(a11y_uia_callback callback,
                          uint64_t session,
                          uint64_t provider,
                          void *context) {
    if (callback == 0) {
        return 0;
    }
    return callback(session, provider, 0, context);
}

uint32_t a11y_uia_release(a11y_uia_callback callback,
                          uint64_t session,
                          uint64_t provider,
                          void *context) {
    if (callback == 0) {
        return 0;
    }
    return callback(session, provider, 0, context);
}

a11y_uia_hresult a11y_uia_dispatch_provider_method(
    a11y_uia_callback callback,
    uint64_t session,
    uint64_t provider,
    uint32_t method,
    void *context) {
    if (callback == 0) {
        return (a11y_uia_hresult)0x80004005u;
    }
    return (a11y_uia_hresult)callback(session, provider, method, context);
}

a11y_uia_hresult a11y_uia_dispatch_provider_frame(
    a11y_uia_callback callback,
    const uint64_t *frame,
    void *context) {
    if (callback == 0 || frame == 0) {
        return (a11y_uia_hresult)0x80004005u;
    }
    return (a11y_uia_hresult)callback(frame[0], frame[1],
                                      (uint32_t)frame[2], context);
}

a11y_uia_hresult a11y_uia_dispatch_provider_full_frame(
    a11y_uia_frame_callback callback,
    const uint64_t *frame,
    void *context) {
    if (callback == 0 || frame == 0) {
        return (a11y_uia_hresult)0x80004005u;
    }
    return (a11y_uia_hresult)callback(frame, context);
}

void *a11y_uia_copy_bstr(const uint16_t *text, uint64_t units) {
    size_t bytes;
    uint16_t *copy;

    if (text == 0 && units != 0) {
        return 0;
    }
    if (units > ((uint64_t)(SIZE_MAX / sizeof(uint16_t)) - 1u)) {
        return 0;
    }

    bytes = (size_t)(units + 1u) * sizeof(uint16_t);
    copy = (uint16_t *)malloc(bytes);
    if (copy == 0) {
        return 0;
    }
    if (units != 0) {
        memcpy(copy, text, (size_t)units * sizeof(uint16_t));
    }
    copy[units] = 0;
    return copy;
}

void a11y_uia_destroy_bstr(void *text) {
    free(text);
}

void *a11y_uia_copy_uint32_safearray(const uint32_t *items, uint64_t count) {
    uint32_t *copy;

    if (items == 0 && count != 0) {
        return 0;
    }
    if (count > (uint64_t)(SIZE_MAX / sizeof(uint32_t))) {
        return 0;
    }

    copy = (uint32_t *)malloc((size_t)count * sizeof(uint32_t));
    if (copy == 0 && count != 0) {
        return 0;
    }
    if (count != 0) {
        memcpy(copy, items, (size_t)count * sizeof(uint32_t));
    }
    return copy;
}

void a11y_uia_destroy_safearray(void *items) {
    free(items);
}

a11y_uia_hresult a11y_uia_translate_hresult(a11y_uia_hresult status) {
    return status;
}

uint32_t a11y_uia_probe_client_runtime(
    struct a11y_uia_client_runtime_probe *report) {
#if defined(_WIN32)
    HRESULT hr;
    IUIAutomation *automation = 0;
    IUIAutomationElement *root = 0;
    BSTR name = 0;
    uint32_t initialized_here = 0;

    if (report == 0) {
        return 0;
    }
    memset(report, 0, sizeof(*report));

    hr = CoInitializeEx(0, COINIT_APARTMENTTHREADED);
    report->coinitialize_hresult = (int32_t)hr;
    if (SUCCEEDED(hr)) {
        report->coinitialized = 1;
        initialized_here = 1;
    } else if (hr == RPC_E_CHANGED_MODE) {
        report->coinitialized = 1;
    } else {
        return 0;
    }

    hr = CoCreateInstance(&CLSID_CUIAutomation, 0, CLSCTX_INPROC_SERVER,
                          &IID_IUIAutomation, (void **)&automation);
    report->cocreate_hresult = (int32_t)hr;
    if (FAILED(hr) || automation == 0) {
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }
    report->automation_created = 1;

    hr = IUIAutomation_GetRootElement(automation, &root);
    report->get_root_hresult = (int32_t)hr;
    if (SUCCEEDED(hr) && root != 0) {
        report->root_element_obtained = 1;
        hr = IUIAutomationElement_get_CurrentName(root, &name);
        report->get_name_hresult = (int32_t)hr;
        if (SUCCEEDED(hr)) {
            report->root_name_obtained = 1;
        }
        if (name != 0) {
            SysFreeString(name);
        }
        IUIAutomationElement_Release(root);
    }

    IUIAutomation_Release(automation);
    if (initialized_here) {
        CoUninitialize();
    }

    report->client_runtime_available =
        report->coinitialized && report->automation_created
        && report->root_element_obtained;
    return report->client_runtime_available;
#else
    if (report != 0) {
        memset(report, 0, sizeof(*report));
    }
    return 0;
#endif
}

uint32_t a11y_uia_probe_host_window_handshake(
    struct a11y_uia_host_window_probe *report) {
#if defined(_WIN32)
    HINSTANCE instance;
    WNDCLASSEXW wc;
    HWND hwnd;
    LRESULT result;

    if (report == 0) {
        return 0;
    }
    memset(report, 0, sizeof(*report));

    instance = GetModuleHandleW(0);
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = a11y_uia_probe_window_proc;
    wc.hInstance = instance;
    wc.lpszClassName = a11y_uia_probe_class_name;

    if (RegisterClassExW(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS) {
        report->window_class_registered = 1;
    } else {
        report->register_error = (int32_t)GetLastError();
        return 0;
    }

    hwnd = CreateWindowExW(0, a11y_uia_probe_class_name,
                           L"A11yKit UIA Host Probe",
                           WS_OVERLAPPEDWINDOW,
                           CW_USEDEFAULT, CW_USEDEFAULT, 1, 1,
                           0, 0, instance, 0);
    if (hwnd == 0) {
        report->create_error = (int32_t)GetLastError();
        return 0;
    }
    report->window_created = 1;
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)report);

    result = SendMessageW(hwnd, WM_GETOBJECT, 0, UiaRootObjectId);
    (void)result;

    if (DestroyWindow(hwnd)) {
        report->window_destroyed = 1;
    }

    return report->window_class_registered
        && report->window_created
        && report->wm_getobject_sent
        && report->uia_root_object_id_matched
        && report->return_raw_element_provider_called
        && report->null_provider_returned_zero
        && report->window_destroyed;
#else
    if (report != 0) {
        memset(report, 0, sizeof(*report));
    }
    return 0;
#endif
}

uint32_t a11y_uia_probe_minimal_provider_host_window(
    struct a11y_uia_minimal_provider_host_window_probe *report) {
#if defined(_WIN32)
    HRESULT hr;
    HINSTANCE instance;
    WNDCLASSEXW wc;
    HWND hwnd;
    struct a11y_uia_minimal_provider *provider;
    struct a11y_uia_minimal_provider_window_context context;
    IUIAutomation *automation = 0;
    IUIAutomationElement *element = 0;
    uint32_t initialized_here = 0;

    if (report == 0) {
        return 0;
    }
    memset(report, 0, sizeof(*report));

    hr = CoInitializeEx(0, COINIT_APARTMENTTHREADED);
    report->coinitialize_hresult = (int32_t)hr;
    if (SUCCEEDED(hr)) {
        report->coinitialized = 1;
        initialized_here = 1;
    } else if (hr == RPC_E_CHANGED_MODE) {
        report->coinitialized = 1;
    } else {
        return 0;
    }

    provider = (struct a11y_uia_minimal_provider *)calloc(1, sizeof(*provider));
    if (provider == 0) {
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }
    provider->lpVtbl = &a11y_uia_minimal_provider_vtbl;
    provider->refs = 1;
    provider->report = report;
    report->provider_created = 1;
    report->provider_final_ref_count = 1;

    instance = GetModuleHandleW(0);
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = a11y_uia_minimal_provider_probe_window_proc;
    wc.hInstance = instance;
    wc.lpszClassName = a11y_uia_minimal_provider_probe_class_name;

    if (RegisterClassExW(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS) {
        report->window_class_registered = 1;
    } else {
        report->register_error = (int32_t)GetLastError();
        IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }

    hwnd = CreateWindowExW(0, a11y_uia_minimal_provider_probe_class_name,
                           L"A11yKit UIA Minimal Provider Probe",
                           WS_OVERLAPPEDWINDOW,
                           CW_USEDEFAULT, CW_USEDEFAULT, 1, 1,
                           0, 0, instance, 0);
    if (hwnd == 0) {
        report->create_error = (int32_t)GetLastError();
        IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }
    report->window_created = 1;
    provider->host_hwnd = hwnd;
    context.report = report;
    context.provider = (IRawElementProviderSimple *)provider;
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)&context);

    (void)SendMessageW(hwnd, WM_GETOBJECT, 0, UiaRootObjectId);

    hr = CoCreateInstance(&CLSID_CUIAutomation, 0, CLSCTX_INPROC_SERVER,
                          &IID_IUIAutomation, (void **)&automation);
    report->cocreate_hresult = (int32_t)hr;
    if (SUCCEEDED(hr) && automation != 0) {
        report->element_from_handle_called = 1;
        hr = IUIAutomation_ElementFromHandle(automation, hwnd, &element);
        report->element_from_handle_hresult = (int32_t)hr;
        if (SUCCEEDED(hr) && element != 0) {
            report->element_from_handle_succeeded = 1;
            IUIAutomationElement_Release(element);
        }
        IUIAutomation_Release(automation);
    }

    SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
    if (DestroyWindow(hwnd)) {
        report->window_destroyed = 1;
    }

    IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);

    if (initialized_here) {
        CoUninitialize();
    }

    return report->coinitialized
        && report->window_class_registered
        && report->window_created
        && report->provider_created
        && report->wm_getobject_sent
        && report->uia_root_object_id_matched
        && report->return_raw_element_provider_called
        && report->provider_release_called
        && report->window_destroyed;
#else
    if (report != 0) {
        memset(report, 0, sizeof(*report));
    }
    return 0;
#endif
}

uint32_t a11y_uia_probe_callback_provider_host_window(
    uint64_t session,
    uint64_t provider_id,
    uint64_t object_token,
    uint32_t provider_options_method,
    uint32_t pattern_provider_method,
    uint32_t property_value_method,
    uint32_t host_raw_element_provider_method,
    uint32_t fragment_navigate_method,
    uint32_t fragment_runtime_id_method,
    uint32_t fragment_bounding_rectangle_method,
    uint32_t fragment_embedded_roots_method,
    uint32_t fragment_set_focus_method,
    uint32_t fragment_root_method,
    uint32_t root_from_point_method,
    uint32_t root_get_focus_method,
    uint32_t invoke_provider_invoke_method,
    uint32_t toggle_provider_toggle_method,
    uint32_t expand_collapse_provider_expand_method,
    uint32_t expand_collapse_provider_collapse_method,
    uint32_t scroll_item_provider_scroll_into_view_method,
    uint32_t selection_item_provider_select_method,
    uint32_t selection_item_provider_add_to_selection_method,
    uint32_t selection_item_provider_remove_from_selection_method,
    uint32_t selection_item_provider_get_is_selected_method,
    uint32_t selection_item_provider_get_selection_container_method,
    uint32_t range_value_provider_set_value_method,
    uint32_t range_value_provider_get_value_method,
    uint32_t range_value_provider_get_is_read_only_method,
    uint32_t range_value_provider_get_maximum_method,
    uint32_t range_value_provider_get_minimum_method,
    uint32_t range_value_provider_get_large_change_method,
    uint32_t range_value_provider_get_small_change_method,
    uint32_t window_provider_close_method,
    uint32_t window_provider_get_can_maximize_method,
    uint32_t window_provider_get_can_minimize_method,
    uint32_t window_provider_get_is_modal_method,
    uint32_t window_provider_get_visual_state_method,
    uint32_t window_provider_get_interaction_state_method,
    uint32_t advise_events_advise_method,
    uint32_t advise_events_unadvise_method,
    a11y_uia_callback callback,
    a11y_uia_frame_callback frame_callback,
    a11y_uia_value_callback value_callback,
    a11y_uia_uint32_array_callback uint32_array_callback,
    a11y_uia_rectangle_callback rectangle_callback,
    a11y_uia_boolean_callback boolean_callback,
    a11y_uia_pattern_callback pattern_callback,
    a11y_uia_state_callback state_callback,
    a11y_uia_range_value_callback range_value_callback,
    a11y_uia_range_value_query_callback range_value_query_callback,
    a11y_uia_window_query_callback window_query_callback,
    void *callback_context,
    struct a11y_uia_callback_provider_host_window_probe *report) {
#if defined(_WIN32)
    HRESULT hr;
    HINSTANCE instance;
    WNDCLASSEXW wc;
    HWND hwnd;
    struct a11y_uia_callback_provider *provider;
    struct a11y_uia_callback_provider_window_context context;
    enum ProviderOptions options;
    VARIANT property_value;
    IUnknown *pattern_provider = 0;
    IInvokeProvider *invoke_provider = 0;
    IToggleProvider *toggle_provider = 0;
    enum ToggleState toggle_state = ToggleState_Off;
    IExpandCollapseProvider *expand_collapse_provider = 0;
    enum ExpandCollapseState expand_collapse_state =
        ExpandCollapseState_Collapsed;
    IScrollItemProvider *scroll_item_provider = 0;
    ISelectionItemProvider *selection_item_provider = 0;
    IRawElementProviderSimple *selection_container = 0;
    BOOL selection_item_selected = FALSE;
    IRangeValueProvider *range_value_provider = 0;
    double range_value_numeric = 0.0;
    BOOL range_value_bool = FALSE;
    IWindowProvider *window_provider = 0;
    BOOL window_bool = FALSE;
    enum WindowVisualState window_visual_state = WindowVisualState_Normal;
    enum WindowInteractionState window_interaction_state =
        WindowInteractionState_Running;
    IRawElementProviderAdviseEvents *advise_events_provider = 0;
    IRawElementProviderSimple *host_provider = 0;
    IRawElementProviderFragment *fragment = 0;
    IRawElementProviderFragment *fragment_result = 0;
    IRawElementProviderFragmentRoot *fragment_root = 0;
    SAFEARRAY *fragment_array = 0;
    struct UiaRect rectangle;
    uint32_t initialized_here = 0;

    if (report == 0) {
        return 0;
    }
    memset(report, 0, sizeof(*report));

    if ((callback == 0 && frame_callback == 0) || session == 0 || provider_id == 0
        || object_token == 0
        || provider_options_method == 0 || pattern_provider_method == 0
        || property_value_method == 0 || host_raw_element_provider_method == 0
        || fragment_navigate_method == 0 || fragment_runtime_id_method == 0
        || fragment_bounding_rectangle_method == 0
        || fragment_embedded_roots_method == 0 || fragment_set_focus_method == 0
        || fragment_root_method == 0 || root_from_point_method == 0
        || root_get_focus_method == 0
        || invoke_provider_invoke_method == 0
        || toggle_provider_toggle_method == 0
        || expand_collapse_provider_expand_method == 0
        || expand_collapse_provider_collapse_method == 0
        || scroll_item_provider_scroll_into_view_method == 0
        || selection_item_provider_select_method == 0
        || selection_item_provider_add_to_selection_method == 0
        || selection_item_provider_remove_from_selection_method == 0
        || selection_item_provider_get_is_selected_method == 0
        || selection_item_provider_get_selection_container_method == 0
        || range_value_provider_set_value_method == 0
        || range_value_provider_get_value_method == 0
        || range_value_provider_get_is_read_only_method == 0
        || range_value_provider_get_maximum_method == 0
        || range_value_provider_get_minimum_method == 0
        || range_value_provider_get_large_change_method == 0
        || range_value_provider_get_small_change_method == 0
        || window_provider_close_method == 0
        || window_provider_get_can_maximize_method == 0
        || window_provider_get_can_minimize_method == 0
        || window_provider_get_is_modal_method == 0
        || window_provider_get_visual_state_method == 0
        || window_provider_get_interaction_state_method == 0
        || advise_events_advise_method == 0
        || advise_events_unadvise_method == 0
        || range_value_callback == 0
        || range_value_query_callback == 0
        || window_query_callback == 0) {
        return 0;
    }

    hr = CoInitializeEx(0, COINIT_APARTMENTTHREADED);
    report->coinitialize_hresult = (int32_t)hr;
    if (SUCCEEDED(hr)) {
        report->coinitialized = 1;
        initialized_here = 1;
    } else if (hr == RPC_E_CHANGED_MODE) {
        report->coinitialized = 1;
    } else {
        return 0;
    }

    provider =
        (struct a11y_uia_callback_provider *)calloc(1, sizeof(*provider));
    if (provider == 0) {
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }
    provider->fragment_iface =
        (struct a11y_uia_callback_provider_fragment_iface *)
            calloc(1, sizeof(*provider->fragment_iface));
    provider->fragment_root_iface =
        (struct a11y_uia_callback_provider_fragment_root_iface *)
            calloc(1, sizeof(*provider->fragment_root_iface));
    provider->invoke_iface =
        (struct a11y_uia_callback_provider_invoke_iface *)
            calloc(1, sizeof(*provider->invoke_iface));
    provider->toggle_iface =
        (struct a11y_uia_callback_provider_toggle_iface *)
            calloc(1, sizeof(*provider->toggle_iface));
    provider->expand_collapse_iface =
        (struct a11y_uia_callback_provider_expand_collapse_iface *)
            calloc(1, sizeof(*provider->expand_collapse_iface));
    provider->scroll_item_iface =
        (struct a11y_uia_callback_provider_scroll_item_iface *)
            calloc(1, sizeof(*provider->scroll_item_iface));
    provider->selection_item_iface =
        (struct a11y_uia_callback_provider_selection_item_iface *)
            calloc(1, sizeof(*provider->selection_item_iface));
    provider->range_value_iface =
        (struct a11y_uia_callback_provider_range_value_iface *)
            calloc(1, sizeof(*provider->range_value_iface));
    provider->window_iface =
        (struct a11y_uia_callback_provider_window_iface *)
            calloc(1, sizeof(*provider->window_iface));
    provider->advise_events_iface =
        (struct a11y_uia_callback_provider_advise_events_iface *)
            calloc(1, sizeof(*provider->advise_events_iface));
    if (provider->fragment_iface == 0 || provider->fragment_root_iface == 0
        || provider->invoke_iface == 0 || provider->toggle_iface == 0
        || provider->expand_collapse_iface == 0
        || provider->scroll_item_iface == 0
        || provider->selection_item_iface == 0
        || provider->range_value_iface == 0
        || provider->window_iface == 0
        || provider->advise_events_iface == 0) {
        free(provider->fragment_iface);
        free(provider->fragment_root_iface);
        free(provider->invoke_iface);
        free(provider->toggle_iface);
        free(provider->expand_collapse_iface);
        free(provider->scroll_item_iface);
        free(provider->selection_item_iface);
        free(provider->range_value_iface);
        free(provider->window_iface);
        free(provider->advise_events_iface);
        free(provider);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }
    provider->lpVtbl = &a11y_uia_callback_provider_vtbl;
    provider->fragment_iface->lpVtbl = &a11y_uia_callback_fragment_vtbl;
    provider->fragment_iface->owner = provider;
    provider->fragment_root_iface->lpVtbl =
        &a11y_uia_callback_fragment_root_vtbl;
    provider->fragment_root_iface->owner = provider;
    provider->invoke_iface->lpVtbl = &a11y_uia_callback_invoke_vtbl;
    provider->invoke_iface->owner = provider;
    provider->toggle_iface->lpVtbl = &a11y_uia_callback_toggle_vtbl;
    provider->toggle_iface->owner = provider;
    provider->expand_collapse_iface->lpVtbl =
        &a11y_uia_callback_expand_collapse_vtbl;
    provider->expand_collapse_iface->owner = provider;
    provider->scroll_item_iface->lpVtbl =
        &a11y_uia_callback_scroll_item_vtbl;
    provider->scroll_item_iface->owner = provider;
    provider->selection_item_iface->lpVtbl =
        &a11y_uia_callback_selection_item_vtbl;
    provider->selection_item_iface->owner = provider;
    provider->range_value_iface->lpVtbl =
        &a11y_uia_callback_range_value_vtbl;
    provider->range_value_iface->owner = provider;
    provider->window_iface->lpVtbl = &a11y_uia_callback_window_vtbl;
    provider->window_iface->owner = provider;
    provider->advise_events_iface->lpVtbl =
        &a11y_uia_callback_advise_events_vtbl;
    provider->advise_events_iface->owner = provider;
    provider->refs = 1;
    provider->session = session;
    provider->provider = provider_id;
    provider->object_token = object_token;
    provider->provider_options_method = provider_options_method;
    provider->pattern_provider_method = pattern_provider_method;
    provider->property_value_method = property_value_method;
    provider->host_raw_element_provider_method = host_raw_element_provider_method;
    provider->fragment_navigate_method = fragment_navigate_method;
    provider->fragment_runtime_id_method = fragment_runtime_id_method;
    provider->fragment_bounding_rectangle_method =
        fragment_bounding_rectangle_method;
    provider->fragment_embedded_roots_method = fragment_embedded_roots_method;
    provider->fragment_set_focus_method = fragment_set_focus_method;
    provider->fragment_root_method = fragment_root_method;
    provider->root_from_point_method = root_from_point_method;
    provider->root_get_focus_method = root_get_focus_method;
    provider->invoke_provider_invoke_method = invoke_provider_invoke_method;
    provider->toggle_provider_toggle_method = toggle_provider_toggle_method;
    provider->expand_collapse_provider_expand_method =
        expand_collapse_provider_expand_method;
    provider->expand_collapse_provider_collapse_method =
        expand_collapse_provider_collapse_method;
    provider->scroll_item_provider_scroll_into_view_method =
        scroll_item_provider_scroll_into_view_method;
    provider->selection_item_provider_select_method =
        selection_item_provider_select_method;
    provider->selection_item_provider_add_to_selection_method =
        selection_item_provider_add_to_selection_method;
    provider->selection_item_provider_remove_from_selection_method =
        selection_item_provider_remove_from_selection_method;
    provider->selection_item_provider_get_is_selected_method =
        selection_item_provider_get_is_selected_method;
    provider->selection_item_provider_get_selection_container_method =
        selection_item_provider_get_selection_container_method;
    provider->range_value_provider_set_value_method =
        range_value_provider_set_value_method;
    provider->range_value_provider_get_value_method =
        range_value_provider_get_value_method;
    provider->range_value_provider_get_is_read_only_method =
        range_value_provider_get_is_read_only_method;
    provider->range_value_provider_get_maximum_method =
        range_value_provider_get_maximum_method;
    provider->range_value_provider_get_minimum_method =
        range_value_provider_get_minimum_method;
    provider->range_value_provider_get_large_change_method =
        range_value_provider_get_large_change_method;
    provider->range_value_provider_get_small_change_method =
        range_value_provider_get_small_change_method;
    provider->window_provider_close_method = window_provider_close_method;
    provider->window_provider_get_can_maximize_method =
        window_provider_get_can_maximize_method;
    provider->window_provider_get_can_minimize_method =
        window_provider_get_can_minimize_method;
    provider->window_provider_get_is_modal_method =
        window_provider_get_is_modal_method;
    provider->window_provider_get_visual_state_method =
        window_provider_get_visual_state_method;
    provider->window_provider_get_interaction_state_method =
        window_provider_get_interaction_state_method;
    provider->advise_events_advise_method = advise_events_advise_method;
    provider->advise_events_unadvise_method = advise_events_unadvise_method;
    provider->callback = callback;
    provider->frame_callback = frame_callback;
    provider->value_callback = value_callback;
    provider->uint32_array_callback = uint32_array_callback;
    provider->rectangle_callback = rectangle_callback;
    provider->boolean_callback = boolean_callback;
    provider->pattern_callback = pattern_callback;
    provider->state_callback = state_callback;
    provider->range_value_callback = range_value_callback;
    provider->range_value_query_callback = range_value_query_callback;
    provider->window_query_callback = window_query_callback;
    provider->callback_context = callback_context;
    provider->report = report;
    report->provider_created = 1;
    report->provider_final_ref_count = 1;

    instance = GetModuleHandleW(0);
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = a11y_uia_callback_provider_probe_window_proc;
    wc.hInstance = instance;
    wc.lpszClassName = a11y_uia_callback_provider_probe_class_name;

    if (RegisterClassExW(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS) {
        report->window_class_registered = 1;
    } else {
        report->register_error = (int32_t)GetLastError();
        IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }

    hwnd = CreateWindowExW(0, a11y_uia_callback_provider_probe_class_name,
                           L"A11yKit UIA Callback Provider Probe",
                           WS_OVERLAPPEDWINDOW,
                           CW_USEDEFAULT, CW_USEDEFAULT, 1, 1,
                           0, 0, instance, 0);
    if (hwnd == 0) {
        report->create_error = (int32_t)GetLastError();
        IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }
    report->window_created = 1;
    context.report = report;
    context.provider = (IRawElementProviderSimple *)provider;
    SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)&context);

    (void)SendMessageW(hwnd, WM_GETOBJECT, 0, UiaRootObjectId);

    hr = IRawElementProviderSimple_get_ProviderOptions
        ((IRawElementProviderSimple *)provider, &options);
    (void)options;
    report->provider_options_hresult = (int32_t)hr;

    hr = IRawElementProviderSimple_GetPatternProvider
        ((IRawElementProviderSimple *)provider, UIA_InvokePatternId,
         &pattern_provider);
    report->pattern_provider_hresult = (int32_t)hr;
    if (pattern_provider != 0) {
        hr = IUnknown_QueryInterface(pattern_provider, &IID_IInvokeProvider,
                                     (void **)&invoke_provider);
        if (SUCCEEDED(hr) && invoke_provider != 0) {
            hr = IInvokeProvider_Invoke(invoke_provider);
            report->invoke_provider_invoke_hresult = (int32_t)hr;
            IInvokeProvider_Release(invoke_provider);
            invoke_provider = 0;
        } else {
            report->invoke_provider_invoke_hresult = (int32_t)hr;
        }
        IUnknown_Release(pattern_provider);
        pattern_provider = 0;
    }

    hr = IRawElementProviderSimple_GetPatternProvider
        ((IRawElementProviderSimple *)provider, UIA_TogglePatternId,
         &pattern_provider);
    if (pattern_provider != 0) {
        hr = IUnknown_QueryInterface(pattern_provider, &IID_IToggleProvider,
                                     (void **)&toggle_provider);
        if (SUCCEEDED(hr) && toggle_provider != 0) {
            hr = IToggleProvider_Toggle(toggle_provider);
            report->toggle_provider_toggle_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IToggleProvider_get_ToggleState(toggle_provider,
                                                     &toggle_state);
            }
            report->toggle_provider_get_state_hresult = (int32_t)hr;
            IToggleProvider_Release(toggle_provider);
            toggle_provider = 0;
        } else {
            report->toggle_provider_toggle_hresult = (int32_t)hr;
            report->toggle_provider_get_state_hresult = (int32_t)hr;
        }
        IUnknown_Release(pattern_provider);
        pattern_provider = 0;
    }

    hr = IRawElementProviderSimple_GetPatternProvider
        ((IRawElementProviderSimple *)provider, UIA_ExpandCollapsePatternId,
         &pattern_provider);
    if (pattern_provider != 0) {
        hr = IUnknown_QueryInterface(pattern_provider,
                                     &IID_IExpandCollapseProvider,
                                     (void **)&expand_collapse_provider);
        if (SUCCEEDED(hr) && expand_collapse_provider != 0) {
            hr = IExpandCollapseProvider_Expand(expand_collapse_provider);
            report->expand_collapse_provider_expand_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IExpandCollapseProvider_Collapse
                    (expand_collapse_provider);
            }
            report->expand_collapse_provider_collapse_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IExpandCollapseProvider_get_ExpandCollapseState
                    (expand_collapse_provider, &expand_collapse_state);
            }
            report->expand_collapse_provider_get_state_hresult =
                (int32_t)hr;
            IExpandCollapseProvider_Release(expand_collapse_provider);
            expand_collapse_provider = 0;
        } else {
            report->expand_collapse_provider_expand_hresult = (int32_t)hr;
            report->expand_collapse_provider_collapse_hresult = (int32_t)hr;
            report->expand_collapse_provider_get_state_hresult = (int32_t)hr;
        }
        IUnknown_Release(pattern_provider);
        pattern_provider = 0;
    }

    hr = IRawElementProviderSimple_QueryInterface(
        (IRawElementProviderSimple *)provider,
        &IID_IRawElementProviderAdviseEvents,
        (void **)&advise_events_provider);
    if (SUCCEEDED(hr) && advise_events_provider != 0) {
        hr = IRawElementProviderAdviseEvents_AdviseEventAdded
            (advise_events_provider, UIA_AutomationFocusChangedEventId, 0);
        report->advise_events_advise_hresult = (int32_t)hr;
        if (SUCCEEDED(hr)) {
            hr = IRawElementProviderAdviseEvents_AdviseEventRemoved
                (advise_events_provider, UIA_AutomationFocusChangedEventId, 0);
        }
        report->advise_events_unadvise_hresult = (int32_t)hr;
        IRawElementProviderAdviseEvents_Release(advise_events_provider);
        advise_events_provider = 0;
    } else {
        report->advise_events_advise_hresult = (int32_t)hr;
        report->advise_events_unadvise_hresult = (int32_t)hr;
    }

    hr = IRawElementProviderSimple_GetPatternProvider
        ((IRawElementProviderSimple *)provider, UIA_ScrollItemPatternId,
         &pattern_provider);
    if (pattern_provider != 0) {
        hr = IUnknown_QueryInterface(pattern_provider,
                                     &IID_IScrollItemProvider,
                                     (void **)&scroll_item_provider);
        if (SUCCEEDED(hr) && scroll_item_provider != 0) {
            hr = IScrollItemProvider_ScrollIntoView(scroll_item_provider);
            report->scroll_item_provider_scroll_into_view_hresult =
                (int32_t)hr;
            IScrollItemProvider_Release(scroll_item_provider);
            scroll_item_provider = 0;
        } else {
            report->scroll_item_provider_scroll_into_view_hresult =
                (int32_t)hr;
        }
        IUnknown_Release(pattern_provider);
        pattern_provider = 0;
    }

    hr = IRawElementProviderSimple_GetPatternProvider
        ((IRawElementProviderSimple *)provider, UIA_SelectionItemPatternId,
         &pattern_provider);
    if (pattern_provider != 0) {
        hr = IUnknown_QueryInterface(pattern_provider,
                                     &IID_ISelectionItemProvider,
                                     (void **)&selection_item_provider);
        if (SUCCEEDED(hr) && selection_item_provider != 0) {
            hr = ISelectionItemProvider_Select(selection_item_provider);
            report->selection_item_provider_select_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = ISelectionItemProvider_AddToSelection
                    (selection_item_provider);
            }
            report->selection_item_provider_add_to_selection_hresult =
                (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = ISelectionItemProvider_RemoveFromSelection
                    (selection_item_provider);
            }
            report->selection_item_provider_remove_from_selection_hresult =
                (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = ISelectionItemProvider_get_IsSelected
                    (selection_item_provider, &selection_item_selected);
            }
            report->selection_item_provider_get_is_selected_hresult =
                (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = ISelectionItemProvider_get_SelectionContainer
                    (selection_item_provider, &selection_container);
            }
            report->selection_item_provider_get_selection_container_hresult =
                (int32_t)hr;
            if (selection_container != 0) {
                IRawElementProviderSimple_Release(selection_container);
                selection_container = 0;
            }
            ISelectionItemProvider_Release(selection_item_provider);
            selection_item_provider = 0;
        } else {
            report->selection_item_provider_select_hresult = (int32_t)hr;
            report->selection_item_provider_add_to_selection_hresult =
                (int32_t)hr;
            report->selection_item_provider_remove_from_selection_hresult =
                (int32_t)hr;
            report->selection_item_provider_get_is_selected_hresult =
                (int32_t)hr;
            report->selection_item_provider_get_selection_container_hresult =
                (int32_t)hr;
        }
        IUnknown_Release(pattern_provider);
        pattern_provider = 0;
    }

    hr = IRawElementProviderSimple_GetPatternProvider
        ((IRawElementProviderSimple *)provider, UIA_WindowPatternId,
         &pattern_provider);
    if (pattern_provider != 0) {
        hr = IUnknown_QueryInterface(pattern_provider, &IID_IWindowProvider,
                                     (void **)&window_provider);
        if (SUCCEEDED(hr) && window_provider != 0) {
            hr = IWindowProvider_Close(window_provider);
            report->window_provider_close_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IWindowProvider_get_CanMaximize
                    (window_provider, &window_bool);
            }
            report->window_provider_get_can_maximize_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IWindowProvider_get_CanMinimize
                    (window_provider, &window_bool);
            }
            report->window_provider_get_can_minimize_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IWindowProvider_get_IsModal
                    (window_provider, &window_bool);
            }
            report->window_provider_get_is_modal_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IWindowProvider_get_WindowVisualState
                    (window_provider, &window_visual_state);
            }
            report->window_provider_get_visual_state_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IWindowProvider_get_WindowInteractionState
                    (window_provider, &window_interaction_state);
            }
            report->window_provider_get_interaction_state_hresult =
                (int32_t)hr;
            IWindowProvider_Release(window_provider);
            window_provider = 0;
        } else {
            report->window_provider_close_hresult = (int32_t)hr;
            report->window_provider_get_can_maximize_hresult = (int32_t)hr;
            report->window_provider_get_can_minimize_hresult = (int32_t)hr;
            report->window_provider_get_is_modal_hresult = (int32_t)hr;
            report->window_provider_get_visual_state_hresult = (int32_t)hr;
            report->window_provider_get_interaction_state_hresult =
                (int32_t)hr;
        }
        IUnknown_Release(pattern_provider);
        pattern_provider = 0;
    }

    hr = IRawElementProviderSimple_GetPatternProvider
        ((IRawElementProviderSimple *)provider, UIA_RangeValuePatternId,
         &pattern_provider);
    if (pattern_provider != 0) {
        hr = IUnknown_QueryInterface(pattern_provider,
                                     &IID_IRangeValueProvider,
                                     (void **)&range_value_provider);
        if (SUCCEEDED(hr) && range_value_provider != 0) {
            hr = IRangeValueProvider_SetValue(range_value_provider, 6.0);
            report->range_value_provider_set_value_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IRangeValueProvider_get_Value
                    (range_value_provider, &range_value_numeric);
            }
            report->range_value_provider_get_value_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IRangeValueProvider_get_IsReadOnly
                    (range_value_provider, &range_value_bool);
            }
            report->range_value_provider_get_is_read_only_hresult =
                (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IRangeValueProvider_get_Maximum
                    (range_value_provider, &range_value_numeric);
            }
            report->range_value_provider_get_maximum_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IRangeValueProvider_get_Minimum
                    (range_value_provider, &range_value_numeric);
            }
            report->range_value_provider_get_minimum_hresult = (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IRangeValueProvider_get_LargeChange
                    (range_value_provider, &range_value_numeric);
            }
            report->range_value_provider_get_large_change_hresult =
                (int32_t)hr;
            if (SUCCEEDED(hr)) {
                hr = IRangeValueProvider_get_SmallChange
                    (range_value_provider, &range_value_numeric);
            }
            report->range_value_provider_get_small_change_hresult =
                (int32_t)hr;
            IRangeValueProvider_Release(range_value_provider);
            range_value_provider = 0;
        } else {
            report->range_value_provider_set_value_hresult = (int32_t)hr;
        }
        IUnknown_Release(pattern_provider);
        pattern_provider = 0;
    }

    VariantInit(&property_value);
    hr = IRawElementProviderSimple_GetPropertyValue
        ((IRawElementProviderSimple *)provider, 30005, &property_value);
    report->property_value_hresult = (int32_t)hr;
    VariantClear(&property_value);

    hr = IRawElementProviderSimple_get_HostRawElementProvider
        ((IRawElementProviderSimple *)provider, &host_provider);
    report->host_raw_element_provider_hresult = (int32_t)hr;
    if (host_provider != 0) {
        IRawElementProviderSimple_Release(host_provider);
    }

    hr = IRawElementProviderSimple_QueryInterface(
        (IRawElementProviderSimple *)provider,
        &IID_IRawElementProviderFragment,
        (void **)&fragment);
    if (SUCCEEDED(hr) && fragment != 0) {
        hr = IRawElementProviderFragment_Navigate
            (fragment, NavigateDirection_FirstChild, &fragment_result);
        report->fragment_navigate_hresult = (int32_t)hr;
        if (fragment_result != 0) {
            IRawElementProviderFragment_Release(fragment_result);
            fragment_result = 0;
        }

        hr = IRawElementProviderFragment_GetRuntimeId
            (fragment, &fragment_array);
        report->fragment_runtime_id_hresult = (int32_t)hr;
        if (fragment_array != 0) {
            SafeArrayDestroy(fragment_array);
            fragment_array = 0;
        }

        hr = IRawElementProviderFragment_get_BoundingRectangle
            (fragment, &rectangle);
        report->fragment_bounding_rectangle_hresult = (int32_t)hr;

        hr = IRawElementProviderFragment_GetEmbeddedFragmentRoots
            (fragment, &fragment_array);
        report->fragment_embedded_roots_hresult = (int32_t)hr;
        if (fragment_array != 0) {
            SafeArrayDestroy(fragment_array);
            fragment_array = 0;
        }

        hr = IRawElementProviderFragment_SetFocus(fragment);
        report->fragment_set_focus_hresult = (int32_t)hr;

        hr = IRawElementProviderFragment_get_FragmentRoot
            (fragment, &fragment_root);
        report->fragment_root_hresult = (int32_t)hr;
        if (SUCCEEDED(hr) && fragment_root != 0) {
            hr = IRawElementProviderFragmentRoot_ElementProviderFromPoint
                (fragment_root, 1.0, 2.0, &fragment_result);
            report->root_from_point_hresult = (int32_t)hr;
            if (fragment_result != 0) {
                report->root_from_point_returned_fragment = 1;
                IRawElementProviderFragment_Release(fragment_result);
                fragment_result = 0;
            }

            hr = IRawElementProviderFragmentRoot_GetFocus
                (fragment_root, &fragment_result);
            report->root_get_focus_hresult = (int32_t)hr;
            if (fragment_result != 0) {
                report->root_get_focus_returned_fragment = 1;
                IRawElementProviderFragment_Release(fragment_result);
                fragment_result = 0;
            }
            IRawElementProviderFragmentRoot_Release(fragment_root);
            fragment_root = 0;
        }
        IRawElementProviderFragment_Release(fragment);
        fragment = 0;
    }

    SetWindowLongPtrW(hwnd, GWLP_USERDATA, 0);
    if (DestroyWindow(hwnd)) {
        report->window_destroyed = 1;
    }

    IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);

    if (initialized_here) {
        CoUninitialize();
    }

    return report->coinitialized
        && report->window_class_registered
        && report->window_created
        && report->provider_created
        && report->wm_getobject_sent
        && report->uia_root_object_id_matched
        && report->return_raw_element_provider_called
        && report->provider_options_called
        && report->provider_options_callback_called
        && report->provider_options_callback_succeeded
        && report->options_callback_session == session
        && report->options_callback_provider == provider_id
        && report->options_callback_method == provider_options_method
        && report->pattern_provider_called
        && report->pattern_provider_callback_called
        && report->pattern_provider_callback_succeeded
        && report->pattern_provider_returned_invoke
        && report->invoke_provider_invoke_called
        && report->invoke_provider_invoke_callback_called
        && report->invoke_provider_invoke_callback_succeeded
        && report->invoke_provider_invoke_callback_method ==
            invoke_provider_invoke_method
        && report->pattern_provider_returned_toggle
        && report->toggle_provider_toggle_called
        && report->toggle_provider_toggle_callback_called
        && report->toggle_provider_toggle_callback_succeeded
        && report->toggle_provider_toggle_callback_method ==
            toggle_provider_toggle_method
        && report->pattern_provider_returned_expand_collapse
        && report->expand_collapse_provider_expand_called
        && report->expand_collapse_provider_expand_callback_called
        && report->expand_collapse_provider_expand_callback_succeeded
        && report->expand_collapse_provider_expand_callback_method ==
            expand_collapse_provider_expand_method
        && report->expand_collapse_provider_collapse_called
        && report->expand_collapse_provider_collapse_callback_called
        && report->expand_collapse_provider_collapse_callback_succeeded
        && report->expand_collapse_provider_collapse_callback_method ==
            expand_collapse_provider_collapse_method
        && report->pattern_provider_returned_scroll_item
        && report->scroll_item_provider_scroll_into_view_called
        && report->scroll_item_provider_scroll_into_view_callback_called
        && report->scroll_item_provider_scroll_into_view_callback_succeeded
        && report->scroll_item_provider_scroll_into_view_callback_method ==
            scroll_item_provider_scroll_into_view_method
        && report->pattern_provider_returned_window
        && report->window_provider_close_called
        && report->window_provider_close_callback_called
        && report->window_provider_close_callback_succeeded
        && report->window_provider_close_callback_method ==
            window_provider_close_method
        && report->window_provider_get_can_maximize_callback_succeeded
        && report->window_provider_get_can_maximize_callback_method ==
            window_provider_get_can_maximize_method
        && report->window_provider_get_can_minimize_callback_succeeded
        && report->window_provider_get_can_minimize_callback_method ==
            window_provider_get_can_minimize_method
        && report->window_provider_get_is_modal_callback_succeeded
        && report->window_provider_get_is_modal_callback_method ==
            window_provider_get_is_modal_method
        && report->window_provider_get_visual_state_callback_succeeded
        && report->window_provider_get_visual_state_callback_method ==
            window_provider_get_visual_state_method
        && report->window_provider_get_interaction_state_callback_succeeded
        && report->window_provider_get_interaction_state_callback_method ==
            window_provider_get_interaction_state_method
        && report->pattern_provider_returned_range_value
        && report->range_value_provider_set_value_called
        && report->range_value_provider_set_value_callback_called
        && report->range_value_provider_set_value_callback_succeeded
        && report->range_value_provider_set_value_callback_method ==
            range_value_provider_set_value_method
        && report->range_value_provider_get_value_callback_succeeded
        && report->range_value_provider_get_value_callback_method ==
            range_value_provider_get_value_method
        && report->range_value_provider_get_is_read_only_callback_succeeded
        && report->range_value_provider_get_is_read_only_callback_method ==
            range_value_provider_get_is_read_only_method
        && report->range_value_provider_get_maximum_callback_succeeded
        && report->range_value_provider_get_maximum_callback_method ==
            range_value_provider_get_maximum_method
        && report->range_value_provider_get_minimum_callback_succeeded
        && report->range_value_provider_get_minimum_callback_method ==
            range_value_provider_get_minimum_method
        && report->range_value_provider_get_large_change_callback_succeeded
        && report->range_value_provider_get_large_change_callback_method ==
            range_value_provider_get_large_change_method
        && report->range_value_provider_get_small_change_callback_succeeded
        && report->range_value_provider_get_small_change_callback_method ==
            range_value_provider_get_small_change_method
        && report->advise_events_advise_called
        && report->advise_events_advise_callback_called
        && report->advise_events_advise_callback_succeeded
        && report->advise_events_advise_callback_method ==
            advise_events_advise_method
        && report->advise_events_unadvise_called
        && report->advise_events_unadvise_callback_called
        && report->advise_events_unadvise_callback_succeeded
        && report->advise_events_unadvise_callback_method ==
            advise_events_unadvise_method
        && report->pattern_callback_session == session
        && report->pattern_callback_provider == provider_id
        && report->pattern_callback_method == pattern_provider_method
        && report->property_value_called
        && report->property_value_callback_called
        && report->property_value_callback_succeeded
        && report->property_callback_session == session
        && report->property_callback_provider == provider_id
        && report->property_callback_method == property_value_method
        && report->host_raw_element_provider_called
        && report->host_raw_element_provider_callback_called
        && report->host_raw_element_provider_callback_succeeded
        && report->host_raw_element_provider_returned_host
        && report->host_callback_session == session
        && report->host_callback_provider == provider_id
        && report->host_callback_method == host_raw_element_provider_method
        && report->fragment_query_interface_called
        && report->fragment_query_interface_succeeded
        && report->fragment_navigate_called
        && report->fragment_navigate_callback_called
        && report->fragment_navigate_callback_succeeded
        && report->fragment_navigate_callback_method == fragment_navigate_method
        && report->fragment_runtime_id_called
        && report->fragment_runtime_id_callback_called
        && report->fragment_runtime_id_callback_succeeded
        && report->fragment_runtime_id_callback_method == fragment_runtime_id_method
        && report->fragment_bounding_rectangle_called
        && report->fragment_bounding_rectangle_callback_called
        && report->fragment_bounding_rectangle_callback_succeeded
        && report->fragment_bounding_rectangle_callback_method == fragment_bounding_rectangle_method
        && report->fragment_embedded_roots_called
        && report->fragment_embedded_roots_callback_called
        && report->fragment_embedded_roots_callback_succeeded
        && report->fragment_embedded_roots_callback_method == fragment_embedded_roots_method
        && report->fragment_set_focus_called
        && report->fragment_set_focus_callback_called
        && report->fragment_set_focus_callback_succeeded
        && report->fragment_set_focus_callback_method == fragment_set_focus_method
        && report->fragment_root_called
        && report->fragment_root_callback_called
        && report->fragment_root_callback_succeeded
        && report->fragment_root_callback_method == fragment_root_method
        && report->fragment_root_query_interface_called
        && report->fragment_root_query_interface_succeeded
        && report->root_from_point_called
        && report->root_from_point_callback_called
        && report->root_from_point_callback_succeeded
        && report->root_from_point_returned_fragment
        && report->root_from_point_callback_method == root_from_point_method
        && report->root_get_focus_called
        && report->root_get_focus_callback_called
        && report->root_get_focus_callback_succeeded
        && report->root_get_focus_returned_fragment
        && report->root_get_focus_callback_method == root_get_focus_method
        && report->provider_release_called
        && report->window_destroyed;
#else
    (void)session;
    (void)provider_id;
    (void)object_token;
    (void)provider_options_method;
    (void)pattern_provider_method;
    (void)property_value_method;
    (void)host_raw_element_provider_method;
    (void)fragment_navigate_method;
    (void)fragment_runtime_id_method;
    (void)fragment_bounding_rectangle_method;
    (void)fragment_embedded_roots_method;
    (void)fragment_set_focus_method;
    (void)fragment_root_method;
    (void)root_from_point_method;
    (void)root_get_focus_method;
    (void)invoke_provider_invoke_method;
    (void)toggle_provider_toggle_method;
    (void)expand_collapse_provider_expand_method;
    (void)expand_collapse_provider_collapse_method;
    (void)scroll_item_provider_scroll_into_view_method;
    (void)selection_item_provider_select_method;
    (void)selection_item_provider_add_to_selection_method;
    (void)selection_item_provider_remove_from_selection_method;
    (void)selection_item_provider_get_is_selected_method;
    (void)selection_item_provider_get_selection_container_method;
    (void)range_value_provider_set_value_method;
    (void)range_value_provider_get_value_method;
    (void)range_value_provider_get_is_read_only_method;
    (void)range_value_provider_get_maximum_method;
    (void)range_value_provider_get_minimum_method;
    (void)range_value_provider_get_large_change_method;
    (void)range_value_provider_get_small_change_method;
    (void)window_provider_close_method;
    (void)window_provider_get_can_maximize_method;
    (void)window_provider_get_can_minimize_method;
    (void)window_provider_get_is_modal_method;
    (void)window_provider_get_visual_state_method;
    (void)window_provider_get_interaction_state_method;
    (void)advise_events_advise_method;
    (void)advise_events_unadvise_method;
    (void)callback;
    (void)frame_callback;
    (void)value_callback;
    (void)uint32_array_callback;
    (void)rectangle_callback;
    (void)boolean_callback;
    (void)pattern_callback;
    (void)state_callback;
    (void)range_value_callback;
    (void)range_value_query_callback;
    (void)window_query_callback;
    (void)callback_context;
    if (report != 0) {
        memset(report, 0, sizeof(*report));
    }
    return 0;
#endif
}

void *a11y_uia_create_callback_provider_host_window(
    uint64_t session,
    uint64_t provider_id,
    uint64_t object_token,
    uint32_t provider_options_method,
    uint32_t pattern_provider_method,
    uint32_t property_value_method,
    uint32_t host_raw_element_provider_method,
    uint32_t fragment_navigate_method,
    uint32_t fragment_runtime_id_method,
    uint32_t fragment_bounding_rectangle_method,
    uint32_t fragment_embedded_roots_method,
    uint32_t fragment_set_focus_method,
    uint32_t fragment_root_method,
    uint32_t root_from_point_method,
    uint32_t root_get_focus_method,
    uint32_t invoke_provider_invoke_method,
    uint32_t toggle_provider_toggle_method,
    uint32_t expand_collapse_provider_expand_method,
    uint32_t expand_collapse_provider_collapse_method,
    uint32_t scroll_item_provider_scroll_into_view_method,
    uint32_t selection_item_provider_select_method,
    uint32_t selection_item_provider_add_to_selection_method,
    uint32_t selection_item_provider_remove_from_selection_method,
    uint32_t selection_item_provider_get_is_selected_method,
    uint32_t selection_item_provider_get_selection_container_method,
    uint32_t range_value_provider_set_value_method,
    uint32_t range_value_provider_get_value_method,
    uint32_t range_value_provider_get_is_read_only_method,
    uint32_t range_value_provider_get_maximum_method,
    uint32_t range_value_provider_get_minimum_method,
    uint32_t range_value_provider_get_large_change_method,
    uint32_t range_value_provider_get_small_change_method,
    uint32_t window_provider_close_method,
    uint32_t window_provider_get_can_maximize_method,
    uint32_t window_provider_get_can_minimize_method,
    uint32_t window_provider_get_is_modal_method,
    uint32_t window_provider_get_visual_state_method,
    uint32_t window_provider_get_interaction_state_method,
    uint32_t advise_events_advise_method,
    uint32_t advise_events_unadvise_method,
    a11y_uia_callback callback,
    a11y_uia_frame_callback frame_callback,
    a11y_uia_value_callback value_callback,
    a11y_uia_uint32_array_callback uint32_array_callback,
    a11y_uia_rectangle_callback rectangle_callback,
    a11y_uia_boolean_callback boolean_callback,
    a11y_uia_pattern_callback pattern_callback,
    a11y_uia_state_callback state_callback,
    a11y_uia_range_value_callback range_value_callback,
    a11y_uia_range_value_query_callback range_value_query_callback,
    a11y_uia_window_query_callback window_query_callback,
    void *callback_context) {
#if defined(_WIN32)
    HRESULT hr;
    HINSTANCE instance;
    WNDCLASSEXW wc;
    struct a11y_uia_live_callback_provider_host *host = 0;
    struct a11y_uia_callback_provider *provider = 0;
    uint32_t initialized_here = 0;

    if ((callback == 0 && frame_callback == 0) || session == 0 || provider_id == 0
        || object_token == 0
        || provider_options_method == 0 || pattern_provider_method == 0
        || property_value_method == 0 || host_raw_element_provider_method == 0
        || fragment_navigate_method == 0 || fragment_runtime_id_method == 0
        || fragment_bounding_rectangle_method == 0
        || fragment_embedded_roots_method == 0 || fragment_set_focus_method == 0
        || fragment_root_method == 0 || root_from_point_method == 0
        || root_get_focus_method == 0
        || invoke_provider_invoke_method == 0
        || toggle_provider_toggle_method == 0
        || expand_collapse_provider_expand_method == 0
        || expand_collapse_provider_collapse_method == 0
        || scroll_item_provider_scroll_into_view_method == 0
        || selection_item_provider_select_method == 0
        || selection_item_provider_add_to_selection_method == 0
        || selection_item_provider_remove_from_selection_method == 0
        || selection_item_provider_get_is_selected_method == 0
        || selection_item_provider_get_selection_container_method == 0
        || range_value_provider_set_value_method == 0
        || range_value_provider_get_value_method == 0
        || range_value_provider_get_is_read_only_method == 0
        || range_value_provider_get_maximum_method == 0
        || range_value_provider_get_minimum_method == 0
        || range_value_provider_get_large_change_method == 0
        || range_value_provider_get_small_change_method == 0
        || window_provider_close_method == 0
        || window_provider_get_can_maximize_method == 0
        || window_provider_get_can_minimize_method == 0
        || window_provider_get_is_modal_method == 0
        || window_provider_get_visual_state_method == 0
        || window_provider_get_interaction_state_method == 0
        || advise_events_advise_method == 0
        || advise_events_unadvise_method == 0
        || range_value_callback == 0
        || range_value_query_callback == 0
        || window_query_callback == 0) {
        return 0;
    }

    hr = CoInitializeEx(0, COINIT_APARTMENTTHREADED);
    if (SUCCEEDED(hr)) {
        initialized_here = 1;
    } else if (hr != RPC_E_CHANGED_MODE) {
        return 0;
    }

    host = (struct a11y_uia_live_callback_provider_host *)calloc(1, sizeof(*host));
    provider = (struct a11y_uia_callback_provider *)calloc(1, sizeof(*provider));
    if (host == 0 || provider == 0) {
        free(host);
        free(provider);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }

    provider->fragment_iface =
        (struct a11y_uia_callback_provider_fragment_iface *)
            calloc(1, sizeof(*provider->fragment_iface));
    provider->fragment_root_iface =
        (struct a11y_uia_callback_provider_fragment_root_iface *)
            calloc(1, sizeof(*provider->fragment_root_iface));
    provider->invoke_iface =
        (struct a11y_uia_callback_provider_invoke_iface *)
            calloc(1, sizeof(*provider->invoke_iface));
    provider->toggle_iface =
        (struct a11y_uia_callback_provider_toggle_iface *)
            calloc(1, sizeof(*provider->toggle_iface));
    provider->expand_collapse_iface =
        (struct a11y_uia_callback_provider_expand_collapse_iface *)
            calloc(1, sizeof(*provider->expand_collapse_iface));
    provider->scroll_item_iface =
        (struct a11y_uia_callback_provider_scroll_item_iface *)
            calloc(1, sizeof(*provider->scroll_item_iface));
    provider->selection_item_iface =
        (struct a11y_uia_callback_provider_selection_item_iface *)
            calloc(1, sizeof(*provider->selection_item_iface));
    provider->range_value_iface =
        (struct a11y_uia_callback_provider_range_value_iface *)
            calloc(1, sizeof(*provider->range_value_iface));
    provider->window_iface =
        (struct a11y_uia_callback_provider_window_iface *)
            calloc(1, sizeof(*provider->window_iface));
    provider->advise_events_iface =
        (struct a11y_uia_callback_provider_advise_events_iface *)
            calloc(1, sizeof(*provider->advise_events_iface));
    host->context =
        (struct a11y_uia_callback_provider_window_context *)
            calloc(1, sizeof(*host->context));
    if (provider->fragment_iface == 0 || provider->fragment_root_iface == 0
        || provider->invoke_iface == 0 || provider->toggle_iface == 0
        || provider->expand_collapse_iface == 0
        || provider->scroll_item_iface == 0
        || provider->selection_item_iface == 0
        || provider->range_value_iface == 0
        || provider->window_iface == 0
        || provider->advise_events_iface == 0
        || host->context == 0) {
        free(provider->fragment_iface);
        free(provider->fragment_root_iface);
        free(provider->invoke_iface);
        free(provider->toggle_iface);
        free(provider->expand_collapse_iface);
        free(provider->scroll_item_iface);
        free(provider->selection_item_iface);
        free(provider->range_value_iface);
        free(provider->window_iface);
        free(provider->advise_events_iface);
        free(host->context);
        free(provider);
        free(host);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }

    provider->lpVtbl = &a11y_uia_callback_provider_vtbl;
    provider->fragment_iface->lpVtbl = &a11y_uia_callback_fragment_vtbl;
    provider->fragment_iface->owner = provider;
    provider->fragment_root_iface->lpVtbl =
        &a11y_uia_callback_fragment_root_vtbl;
    provider->fragment_root_iface->owner = provider;
    provider->invoke_iface->lpVtbl = &a11y_uia_callback_invoke_vtbl;
    provider->invoke_iface->owner = provider;
    provider->toggle_iface->lpVtbl = &a11y_uia_callback_toggle_vtbl;
    provider->toggle_iface->owner = provider;
    provider->expand_collapse_iface->lpVtbl =
        &a11y_uia_callback_expand_collapse_vtbl;
    provider->expand_collapse_iface->owner = provider;
    provider->scroll_item_iface->lpVtbl = &a11y_uia_callback_scroll_item_vtbl;
    provider->scroll_item_iface->owner = provider;
    provider->selection_item_iface->lpVtbl =
        &a11y_uia_callback_selection_item_vtbl;
    provider->selection_item_iface->owner = provider;
    provider->range_value_iface->lpVtbl = &a11y_uia_callback_range_value_vtbl;
    provider->range_value_iface->owner = provider;
    provider->window_iface->lpVtbl = &a11y_uia_callback_window_vtbl;
    provider->window_iface->owner = provider;
    provider->advise_events_iface->lpVtbl =
        &a11y_uia_callback_advise_events_vtbl;
    provider->advise_events_iface->owner = provider;
    provider->refs = 1;
    provider->session = session;
    provider->provider = provider_id;
    provider->object_token = object_token;
    provider->provider_options_method = provider_options_method;
    provider->pattern_provider_method = pattern_provider_method;
    provider->property_value_method = property_value_method;
    provider->host_raw_element_provider_method = host_raw_element_provider_method;
    provider->fragment_navigate_method = fragment_navigate_method;
    provider->fragment_runtime_id_method = fragment_runtime_id_method;
    provider->fragment_bounding_rectangle_method = fragment_bounding_rectangle_method;
    provider->fragment_embedded_roots_method = fragment_embedded_roots_method;
    provider->fragment_set_focus_method = fragment_set_focus_method;
    provider->fragment_root_method = fragment_root_method;
    provider->root_from_point_method = root_from_point_method;
    provider->root_get_focus_method = root_get_focus_method;
    provider->invoke_provider_invoke_method = invoke_provider_invoke_method;
    provider->toggle_provider_toggle_method = toggle_provider_toggle_method;
    provider->expand_collapse_provider_expand_method =
        expand_collapse_provider_expand_method;
    provider->expand_collapse_provider_collapse_method =
        expand_collapse_provider_collapse_method;
    provider->scroll_item_provider_scroll_into_view_method =
        scroll_item_provider_scroll_into_view_method;
    provider->selection_item_provider_select_method =
        selection_item_provider_select_method;
    provider->selection_item_provider_add_to_selection_method =
        selection_item_provider_add_to_selection_method;
    provider->selection_item_provider_remove_from_selection_method =
        selection_item_provider_remove_from_selection_method;
    provider->selection_item_provider_get_is_selected_method =
        selection_item_provider_get_is_selected_method;
    provider->selection_item_provider_get_selection_container_method =
        selection_item_provider_get_selection_container_method;
    provider->range_value_provider_set_value_method =
        range_value_provider_set_value_method;
    provider->range_value_provider_get_value_method =
        range_value_provider_get_value_method;
    provider->range_value_provider_get_is_read_only_method =
        range_value_provider_get_is_read_only_method;
    provider->range_value_provider_get_maximum_method =
        range_value_provider_get_maximum_method;
    provider->range_value_provider_get_minimum_method =
        range_value_provider_get_minimum_method;
    provider->range_value_provider_get_large_change_method =
        range_value_provider_get_large_change_method;
    provider->range_value_provider_get_small_change_method =
        range_value_provider_get_small_change_method;
    provider->window_provider_close_method = window_provider_close_method;
    provider->window_provider_get_can_maximize_method =
        window_provider_get_can_maximize_method;
    provider->window_provider_get_can_minimize_method =
        window_provider_get_can_minimize_method;
    provider->window_provider_get_is_modal_method =
        window_provider_get_is_modal_method;
    provider->window_provider_get_visual_state_method =
        window_provider_get_visual_state_method;
    provider->window_provider_get_interaction_state_method =
        window_provider_get_interaction_state_method;
    provider->advise_events_advise_method = advise_events_advise_method;
    provider->advise_events_unadvise_method = advise_events_unadvise_method;
    provider->callback = callback;
    provider->frame_callback = frame_callback;
    provider->value_callback = value_callback;
    provider->uint32_array_callback = uint32_array_callback;
    provider->rectangle_callback = rectangle_callback;
    provider->boolean_callback = boolean_callback;
    provider->pattern_callback = pattern_callback;
    provider->state_callback = state_callback;
    provider->range_value_callback = range_value_callback;
    provider->range_value_query_callback = range_value_query_callback;
    provider->window_query_callback = window_query_callback;
    provider->callback_context = callback_context;
    provider->report = &host->report;
    host->report.coinitialized = 1;
    host->report.provider_created = 1;
    host->report.provider_final_ref_count = 1;

    instance = GetModuleHandleW(0);
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = a11y_uia_callback_provider_probe_window_proc;
    wc.hInstance = instance;
    wc.lpszClassName = a11y_uia_callback_provider_probe_class_name;
    if (RegisterClassExW(&wc) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS) {
        host->report.window_class_registered = 1;
    } else {
        IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);
        free(host->context);
        free(host);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }

    host->hwnd = CreateWindowExW(0, a11y_uia_callback_provider_probe_class_name,
                                 L"A11yKit UIA Provider",
                                 WS_OVERLAPPEDWINDOW,
                                 CW_USEDEFAULT, CW_USEDEFAULT, 1, 1,
                                 0, 0, instance, 0);
    if (host->hwnd == 0) {
        IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);
        free(host->context);
        free(host);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }

    host->provider = provider;
    host->initialized_here = initialized_here;
    host->context->report = &host->report;
    host->context->provider = (IRawElementProviderSimple *)provider;
    SetWindowLongPtrW(host->hwnd, GWLP_USERDATA, (LONG_PTR)host->context);
    host->report.window_created = 1;
    (void)SendMessageW(host->hwnd, WM_GETOBJECT, 0, UiaRootObjectId);
    if (!host->report.return_raw_element_provider_nonzero) {
        SetWindowLongPtrW(host->hwnd, GWLP_USERDATA, 0);
        DestroyWindow(host->hwnd);
        IRawElementProviderSimple_Release((IRawElementProviderSimple *)provider);
        free(host->context);
        free(host);
        if (initialized_here) {
            CoUninitialize();
        }
        return 0;
    }

    return host;
#else
    (void)session;
    (void)provider_id;
    (void)object_token;
    (void)provider_options_method;
    (void)pattern_provider_method;
    (void)property_value_method;
    (void)host_raw_element_provider_method;
    (void)fragment_navigate_method;
    (void)fragment_runtime_id_method;
    (void)fragment_bounding_rectangle_method;
    (void)fragment_embedded_roots_method;
    (void)fragment_set_focus_method;
    (void)fragment_root_method;
    (void)root_from_point_method;
    (void)root_get_focus_method;
    (void)invoke_provider_invoke_method;
    (void)toggle_provider_toggle_method;
    (void)expand_collapse_provider_expand_method;
    (void)expand_collapse_provider_collapse_method;
    (void)scroll_item_provider_scroll_into_view_method;
    (void)selection_item_provider_select_method;
    (void)selection_item_provider_add_to_selection_method;
    (void)selection_item_provider_remove_from_selection_method;
    (void)selection_item_provider_get_is_selected_method;
    (void)selection_item_provider_get_selection_container_method;
    (void)range_value_provider_set_value_method;
    (void)range_value_provider_get_value_method;
    (void)range_value_provider_get_is_read_only_method;
    (void)range_value_provider_get_maximum_method;
    (void)range_value_provider_get_minimum_method;
    (void)range_value_provider_get_large_change_method;
    (void)range_value_provider_get_small_change_method;
    (void)window_provider_close_method;
    (void)window_provider_get_can_maximize_method;
    (void)window_provider_get_can_minimize_method;
    (void)window_provider_get_is_modal_method;
    (void)window_provider_get_visual_state_method;
    (void)window_provider_get_interaction_state_method;
    (void)advise_events_advise_method;
    (void)advise_events_unadvise_method;
    (void)callback;
    (void)frame_callback;
    (void)value_callback;
    (void)uint32_array_callback;
    (void)rectangle_callback;
    (void)boolean_callback;
    (void)pattern_callback;
    (void)state_callback;
    (void)range_value_callback;
    (void)range_value_query_callback;
    (void)window_query_callback;
    (void)callback_context;
    return 0;
#endif
}

void a11y_uia_destroy_callback_provider_host_window(void *handle) {
#if defined(_WIN32)
    struct a11y_uia_live_callback_provider_host *host =
        (struct a11y_uia_live_callback_provider_host *)handle;
    if (host == 0) {
        return;
    }
    if (host->hwnd != 0) {
        SetWindowLongPtrW(host->hwnd, GWLP_USERDATA, 0);
        DestroyWindow(host->hwnd);
        host->hwnd = 0;
    }
    if (host->provider != 0) {
        IRawElementProviderSimple_Release
            ((IRawElementProviderSimple *)host->provider);
        host->provider = 0;
    }
    free(host->context);
    if (host->initialized_here) {
        CoUninitialize();
    }
    free(host);
#else
    (void)handle;
#endif
}

a11y_uia_hresult a11y_uia_raise_automation_event(void *handle,
                                                 uint32_t event_id) {
#if defined(_WIN32)
    struct a11y_uia_live_callback_provider_host *host =
        (struct a11y_uia_live_callback_provider_host *)handle;
    if (host == 0 || host->provider == 0 || event_id == 0) {
        return E_INVALIDARG;
    }
    return (a11y_uia_hresult)UiaRaiseAutomationEvent
        ((IRawElementProviderSimple *)host->provider, (EVENTID)event_id);
#else
    (void)handle;
    (void)event_id;
    return (a11y_uia_hresult)-2147467259;
#endif
}
