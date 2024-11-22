//
//  Constatns.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

// MARK: - Timings API keys

let BE_TIMINGS_EVENT_TIME_KEY = "eventTime"
let BE_TIMINGS_PLUGIN_ID_KEY = "pluginId"
let BE_TIMINGS_PLUGIN_NAME_KEY = "pluginName"
let BE_HEADER_PAGE_INSTANCE_GUID_KEY = "rokt-page-instance-guid"

// MARK: - API keys

let BE_EVENT_DATA_KEY = "eventData"
let BE_VIEW_NAME_KEY = "pageIdentifier"
let BE_SESSION_ID_KEY = "sessionId"
let BE_PAGE_INSTANCE_GUID_KEY = "pageInstanceGuid"
let BE_EVENT_TYPE_KEY = "eventType"
let BE_INSTANCE_GUID = "instanceGuid"
let BE_PARENT_GUID_KEY = "parentGuid"
let BE_CLIENT_TIME_STAMP = "clientTimeStamp"
let BE_METADATA_KEY = "metadata"
let BE_NAME = "name"
let BE_VALUE = "value"
let BE_CAPTURE_METHOD = "captureMethod"
let BE_PAGE_SIGNAL_LOAD = "pageSignalLoadStart"
let BE_PAGE_SIGNAL_COMPLETE = "pageSignalLoadComplete"
let BE_PAGE_RENDER_ENGINE = "pageRenderEngine"
let BE_RENDER_ENGINE_LAYOUTS = "Layouts"
let BE_JWT_TOKEN = "token"
let kEventTimeStamp = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
let kUTCTimeStamp = "UTC"
let kBaseLocale = "en"
let kClientProvided = "ClientProvided"
let kInitiator = "initiator"
let kCloseButton = "CLOSE_BUTTON"
let kNoMoreOfferToShow = "NO_MORE_OFFERS_TO_SHOW"
let kCollapsed = "COLLAPSED"
let kEndMessage = "END_MESSAGE"
let kDismissed = "DISMISSED"
let kPartnerTriggered = "PARTNER_TRIGGERED"

// MARK: - String keys

let kEmbeddedLayoutDoesntExistMessage = "Error embedded layout doesn't exist "
let kUIFontErrorMessage = "Font family not found: "
let kStaticPageError = "Error on static page"
let kInvalidHTMLFormatError = "Error parsing html: "
let kLocationDoesNotExist = " location does not exist"
let kColorInvalid = "The color is invalid: "
let kLayoutInvalid = "The layout is invalid"

// MARK: - Diagnostic error codes

let kAPIExecuteErrorCode = "[EXECUTE]"
let kValidationErrorCode = "[VALIDATION]"
let kWebViewErrorCode = "[WEBVIEW]"
let kUrlErrorCode = "[URL]"
let kViewErrorCode = "[VIEW]"
let kEmptyResponse = "Empty response from API"
let kErrorCode = "code"
let kErrorStackTrace = "stackTrace"
let kErrorSeverity = "severity"

// MARK: Queue

let kSharedDataItemsQueueLabel = "com.rokt.shareddata.items.queue"

// MARK: - SignalViewed constants

let kSignalViewedIntersectThreshold = 0.5
let kSignalViewedTimeThreshold = 1.0

// MARK: - Accessibility

let kPageAnnouncement = "Page %d of %d"
let kOneByOneAnnouncement = "Offer %d of %d"
let kProgressIndicatorAnnouncement = "%d of %d"
let kCloseButtonAnnouncement = "Close button"
let kNextPageButtonAnnouncement = "Next page button"
let kPreviousPageButtonAnnouncement = "Previous page button"
