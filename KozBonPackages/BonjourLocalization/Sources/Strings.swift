// swiftlint:disable file_length

//
//  Strings.swift
//  BonjourLocalization
//
//  Created for the KozBon app.
//

import Foundation

// Type-safe localized string constants for the KozBon app.
// Access strings via nested enums, e.g. `Strings.NavigationTitles.nearbyServices`.
// swiftlint:disable:next type_body_length
public enum Strings {

    // MARK: - Navigation Titles

    public enum NavigationTitles {

        public static var nearbyServices: LocalizedStringResource {
            .init("nav_nearby_services", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var broadcastService: LocalizedStringResource {
            .init("nav_broadcast_service", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var supportedServices: LocalizedStringResource {
            .init("nav_supported_services", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var createTxtRecord: LocalizedStringResource {
            .init("nav_create_txt_record", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var createServiceType: LocalizedStringResource {
            .init("nav_create_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var editServiceType: LocalizedStringResource {
            .init("nav_edit_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var settings: LocalizedStringResource {
            .init("nav_settings", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Tabs

    public enum Tabs {

        public static var bonjour: LocalizedStringResource {
            .init("tab_bonjour", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var supportedServices: LocalizedStringResource {
            .init("tab_supported_services", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var preferences: LocalizedStringResource {
            .init("tab_preferences", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Sections

    public enum Sections {

        public static var published: LocalizedStringResource {
            .init("section_published", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var information: LocalizedStringResource {
            .init("section_information", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var ipAddresses: LocalizedStringResource {
            .init("section_ip_addresses", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtRecords: LocalizedStringResource {
            .init("section_txt_records", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceType: LocalizedStringResource {
            .init("section_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var portNumber: LocalizedStringResource {
            .init("section_port_number", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceDomain: LocalizedStringResource {
            .init("section_service_domain", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var customServiceTypes: LocalizedStringResource {
            .init("section_custom_service_types", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var builtinServiceTypes: LocalizedStringResource {
            .init("section_builtin_service_types", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var recordKey: LocalizedStringResource {
            .init("section_record_key", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var recordValue: LocalizedStringResource {
            .init("section_record_value", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceName: LocalizedStringResource {
            .init("section_service_name", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var bonjourType: LocalizedStringResource {
            .init("section_bonjour_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var additionalDetails: LocalizedStringResource {
            .init("section_additional_details", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Detail Rows

    public enum DetailRows {

        public static var name: LocalizedStringResource {
            .init("detail_name", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var hostname: LocalizedStringResource {
            .init("detail_hostname", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var fullType: LocalizedStringResource {
            .init("detail_full_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var type: LocalizedStringResource {
            .init("detail_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var transportLayer: LocalizedStringResource {
            .init("detail_transport_layer", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var domain: LocalizedStringResource {
            .init("detail_domain", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var protocolInformation: LocalizedStringResource {
            .init("detail_protocol_information", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var details: LocalizedStringResource {
            .init("detail_details", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Buttons

    public enum Buttons {

        public static var create: LocalizedStringResource {
            .init("button_create", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var cancel: LocalizedStringResource {
            .init("button_cancel", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var done: LocalizedStringResource {
            .init("button_done", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var sort: LocalizedStringResource {
            .init("button_sort", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var addTxtRecord: LocalizedStringResource {
            .init("button_add_txt_record", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var remove: LocalizedStringResource {
            .init("button_remove", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var edit: LocalizedStringResource {
            .init("button_edit", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var delete: LocalizedStringResource {
            .init("button_delete", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var ok: LocalizedStringResource {
            .init("button_ok", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var update: LocalizedStringResource {
            .init("button_update", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var broadcastBonjourService: LocalizedStringResource {
            .init("button_broadcast_bonjour_service", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var startScanning: LocalizedStringResource {
            .init("button_start_scanning", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var scanningForServices: LocalizedStringResource {
            .init("loading_scanning_for_services", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var refresh: LocalizedStringResource {
            .init("button_refresh", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var broadcast: LocalizedStringResource {
            .init("button_broadcast", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var createServiceType: LocalizedStringResource {
            .init("button_create_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var createCustomServiceType: LocalizedStringResource {
            .init("button_create_custom_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var broadcastService: LocalizedStringResource {
            .init("button_broadcast_service", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Context Menu Actions

    public enum Actions {

        public static var copyHostname: LocalizedStringResource {
            .init("action_copy_hostname", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyIpAddress: LocalizedStringResource {
            .init("action_copy_ip_address", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyServiceType: LocalizedStringResource {
            .init("action_copy_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyAddress: LocalizedStringResource {
            .init("action_copy_address", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyIpOnly: LocalizedStringResource {
            .init("action_copy_ip_only", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyRecord: LocalizedStringResource {
            .init("action_copy_record", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyValue: LocalizedStringResource {
            .init("action_copy_value", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyFullType: LocalizedStringResource {
            .init("action_copy_full_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyName: LocalizedStringResource {
            .init("action_copy_name", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyType: LocalizedStringResource {
            .init("action_copy_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var copyDetails: LocalizedStringResource {
            .init("action_copy_details", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var openNewWindow: LocalizedStringResource {
            .init("action_open_new_window", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Placeholders

    public enum Placeholders {

        public static var selectServiceType: LocalizedStringResource {
            .init("placeholder_select_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var servicePortNumber: LocalizedStringResource {
            .init("placeholder_service_port_number", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceDomain: LocalizedStringResource {
            .init("placeholder_service_domain", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtRecordKey: LocalizedStringResource {
            .init("placeholder_txt_record_key", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtRecordValue: LocalizedStringResource {
            .init("placeholder_txt_record_value", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceName: LocalizedStringResource {
            .init("placeholder_service_name", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var typeDefinition: LocalizedStringResource {
            .init("placeholder_type_definition", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var additionalInformation: LocalizedStringResource {
            .init("placeholder_additional_information", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var search: LocalizedStringResource {
            .init("placeholder_search", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Errors

    public enum Errors {

        public static var serviceTypeRequired: LocalizedStringResource {
            .init("error_service_type_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var portNumberRequired: LocalizedStringResource {
            .init("error_port_number_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var domainRequired: LocalizedStringResource {
            .init("error_domain_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtKeyRequired: LocalizedStringResource {
            .init("error_txt_key_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtValueRequired: LocalizedStringResource {
            .init("error_txt_value_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtKeyDuplicate: LocalizedStringResource {
            .init("error_txt_key_duplicate", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var nameRequired: LocalizedStringResource {
            .init("error_name_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var typeRequired: LocalizedStringResource {
            .init("error_type_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var detailsRequired: LocalizedStringResource {
            .init("error_details_required", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var alreadyExists: LocalizedStringResource {
            .init("error_already_exists", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static func portMin(_ value: Int) -> String {
            String(format: NSLocalizedString("error_port_min", bundle: Bundle.module, comment: ""), value)
        }

        public static func portMax(_ value: Int) -> String {
            String(format: NSLocalizedString("error_port_max", bundle: Bundle.module, comment: ""), value)
        }

        public static func publishFailed(_ description: String) -> String {
            String(format: NSLocalizedString("error_publish_failed", bundle: Bundle.module, comment: ""), description)
        }
    }

    // MARK: - Empty States

    public enum EmptyStates {

        public static var noActiveServices: LocalizedStringResource {
            .init("empty_no_active_services", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var selectService: LocalizedStringResource {
            .init("empty_select_service", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var selectServiceDescription: LocalizedStringResource {
            .init("empty_select_service_description", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var selectServiceType: LocalizedStringResource {
            .init("empty_select_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var selectServiceTypeDescription: LocalizedStringResource {
            .init("empty_select_service_type_description", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Sort Options

    public enum SortOptions {

        public static var hostNameAsc: LocalizedStringResource {
            .init("sort_host_name_asc", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var hostNameDesc: LocalizedStringResource {
            .init("sort_host_name_desc", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceTypeAsc: LocalizedStringResource {
            .init("sort_service_type_asc", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceTypeDesc: LocalizedStringResource {
            .init("sort_service_type_desc", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Alerts

    public enum Alerts {

        public static var scanError: LocalizedStringResource {
            .init("alert_scan_error", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var deleteServiceType: LocalizedStringResource {
            .init("dialog_delete_service_type", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Accessibility

    public enum Accessibility {

        public static var create: LocalizedStringResource {
            .init("a11y_create", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var createHint: LocalizedStringResource {
            .init("a11y_create_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var createServiceTypeHint: LocalizedStringResource {
            .init("a11y_create_service_type_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var portNumber: LocalizedStringResource {
            .init("a11y_port_number", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceDomain: LocalizedStringResource {
            .init("a11y_service_domain", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceDomainHint: LocalizedStringResource {
            .init("a11y_service_domain_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var addTxtRecordHint: LocalizedStringResource {
            .init("a11y_add_txt_record_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var editRecordHint: LocalizedStringResource {
            .init("a11y_edit_record_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var longPressCopyAddress: LocalizedStringResource {
            .init("a11y_long_press_copy_address", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var longPressCopyRecord: LocalizedStringResource {
            .init("a11y_long_press_copy_record", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtRecordKey: LocalizedStringResource {
            .init("a11y_txt_record_key", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtRecordKeyHint: LocalizedStringResource {
            .init("a11y_txt_record_key_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtRecordValue: LocalizedStringResource {
            .init("a11y_txt_record_value", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var txtRecordValueHint: LocalizedStringResource {
            .init("a11y_txt_record_value_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceName: LocalizedStringResource {
            .init("a11y_service_name", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var serviceNameHint: LocalizedStringResource {
            .init("a11y_service_name_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var bonjourType: LocalizedStringResource {
            .init("a11y_bonjour_type", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var bonjourTypeHint: LocalizedStringResource {
            .init("a11y_bonjour_type_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var additionalDetails: LocalizedStringResource {
            .init("a11y_additional_details", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var additionalDetailsHint: LocalizedStringResource {
            .init("a11y_additional_details_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var selected: LocalizedStringResource {
            .init("a11y_selected", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var notSelected: LocalizedStringResource {
            .init("a11y_not_selected", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var selectServiceTypeHint: LocalizedStringResource {
            .init("a11y_select_service_type_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var editHint: LocalizedStringResource {
            .init("a11y_edit_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var deleteHint: LocalizedStringResource {
            .init("a11y_delete_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static func viewDetails(_ name: String) -> String {
            String(format: NSLocalizedString("a11y_view_details_format", bundle: Bundle.module, comment: ""), name)
        }

        public static func portHint(min: Int, max: Int) -> String {
            String(format: NSLocalizedString("a11y_port_hint_format", bundle: Bundle.module, comment: ""), min, max)
        }

        public static func error(_ message: String) -> String {
            String(format: NSLocalizedString("a11y_error_format", bundle: Bundle.module, comment: ""), message)
        }

        public static func remove(_ name: String) -> String {
            String(format: NSLocalizedString("a11y_remove_format", bundle: Bundle.module, comment: ""), name)
        }

        public static func edit(_ name: String) -> String {
            String(format: NSLocalizedString("a11y_edit_format", bundle: Bundle.module, comment: ""), name)
        }

        public static func delete(_ name: String) -> String {
            String(format: NSLocalizedString("a11y_delete_format", bundle: Bundle.module, comment: ""), name)
        }

        public static func longPressToCopy(_ field: String) -> String {
            String(format: NSLocalizedString("a11y_long_press_copy_format", bundle: Bundle.module, comment: ""), field)
        }
    }

    // MARK: - Settings

    public enum Settings {

        public static var scanning: LocalizedStringResource {
            .init("settings_scanning", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var scanOnLaunch: LocalizedStringResource {
            .init("settings_scan_on_launch", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var display: LocalizedStringResource {
            .init("settings_display", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var defaultSortOrder: LocalizedStringResource {
            .init("settings_default_sort_order", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var sortNone: LocalizedStringResource {
            .init("settings_sort_none", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var sortDefault: LocalizedStringResource {
            .init("settings_sort_default", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var sortHostnameAsc: LocalizedStringResource {
            .init("settings_sort_hostname_asc", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var sortHostnameDesc: LocalizedStringResource {
            .init("settings_sort_hostname_desc", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var sortServiceNameAsc: LocalizedStringResource {
            .init("settings_sort_service_name_asc", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var sortServiceNameDesc: LocalizedStringResource {
            .init("settings_sort_service_name_desc", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var clearCustomServiceTypes: LocalizedStringResource {
            .init("settings_clear_custom_service_types", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var aiAnalysis: LocalizedStringResource {
            .init("settings_ai_analysis", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var aiAnalysisEnabled: LocalizedStringResource {
            .init("settings_ai_analysis_enabled", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var aiAnalysisFooter: LocalizedStringResource {
            .init("settings_ai_analysis_footer", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var aiExpertiseLevel: LocalizedStringResource {
            .init("settings_ai_expertise_level", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var aiBasicSubtitle: LocalizedStringResource {
            .init("settings_ai_basic_subtitle", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var aiTechnicalSubtitle: LocalizedStringResource {
            .init("settings_ai_technical_subtitle", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var resetToDefaults: LocalizedStringResource {
            .init("settings_reset_to_defaults", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var reset: LocalizedStringResource {
            .init("settings_reset", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var resetConfirmationMessage: LocalizedStringResource {
            .init("settings_reset_confirmation_message", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - AI

    public enum AIInsights {

        public static var explainWithAI: LocalizedStringResource {
            .init("button_explain_with_ai", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var insightsTitle: LocalizedStringResource {
            .init("nav_ai_insights", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var generating: LocalizedStringResource {
            .init("ai_generating", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var explainHint: LocalizedStringResource {
            .init("a11y_explain_with_ai_hint", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var basic: LocalizedStringResource {
            .init("ai_expertise_basic", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var technical: LocalizedStringResource {
            .init("ai_expertise_technical", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var moreDetail: LocalizedStringResource {
            .init("ai_more_detail", bundle: .atURL(Bundle.module.bundleURL))
        }

        public static var lessDetail: LocalizedStringResource {
            .init("ai_less_detail", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    // MARK: - Nearby Section Header

    public enum NearbySection {

        public static func title(_ sortTitle: String) -> String {
            String(format: NSLocalizedString("nearby_format", bundle: Bundle.module, comment: ""), sortTitle)
        }

        public static var services: LocalizedStringResource {
            .init("nearby_services", bundle: .atURL(Bundle.module.bundleURL))
        }
    }
}

// swiftlint:enable file_length
