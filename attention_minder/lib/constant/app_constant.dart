// const String baseUrl = "http://13.217.234.177:8000/api/";
const String baseUrl = "http://13.217.234.177/api/";

const String wsBaseUrl = "ws://13.217.234.177:8000";

const String googleOAuthServerClientId =
    "908828655450-tnfd4g2tn7s037j3hkt02skclv8f642u.apps.googleusercontent.com";

// ============================================================================
// AUTHENTICATION ENDPOINTS
// ============================================================================
const String loginEndpoint = "auth/v1/login/";

// ============================================================================
// USER ENDPOINTS
// ============================================================================
const String registrationEndpoint = "users/v1/users/registration";
const String getUserProfileEndpoint = "users/v1/users/get-user-profile";
const String updateProfileEndpoint = "users/v1/users/update-profile";

// Password Reset Endpoints
const String passwordResetRequestEndpoint =
    "users/v1/users/password-reset/request";
const String passwordResetOtpVerifyEndpoint =
    "users/v1/users/password-reset/otp-verify";
const String passwordResetChangeEndpoint =
    "users/v1/users/password-reset/change";
const String socialLoginEndpoint = "users/v1/users/social-login";

// ============================================================================
// SELF ASSESSMENT ENDPOINTS
// ============================================================================
const String getQuestionEndPoint =
    "assessment/v1/self-assessment/get-questions";
const String saveQuestionEndPoint =
    "assessment/v1/self-assessment/save-response";
const String fetchResultEndpoint = "assessment/v1/self-assessment/fetch-result";

// ============================================================================
// FILE HANDLER ENDPOINTS
// ============================================================================
const String getFilesEndpoint = "filehandler/v1/filehandler/list-files";
const String saveFeedbackEndpoint = "filehandler/v1/filehandler/save-feedback";

// ============================================================================
// ATTENTION MANAGEMENT ENDPOINTS
// ============================================================================
const String getProgramDataEndpoint = "attention/v1/get-program-data";
const String getAttentionAssessmentEndpoint = "attention/v1/get-assessment";
const String submitAttentionAssessmentEndpoint =
    "attention/v1/submit-assessment";
const String getDailySessionEndpoint = "attention/v1/get-daily-session";
const String completeSessionEndpoint = "attention/v1/complete-session";
const String saveGoalsEndpoint = "attention/v1/save-goals";
const String getProgressDataEndpoint = "attention/v1/get-progress";
const String saveAiAssessmentScoreEndpoint =
    "assessment/v1/ai-assessment/save-score";

// ============================================================================
// ARTICLES ENDPOINTS
// ============================================================================
const String getArticlesUrlEndpoint = "articles/v1/list";
const String getprogressCardEndpoint = "assessment/v1/self-assessment/progress";

// ============================================================================
// PAYMENT ENDPOINTS
// ============================================================================
const String createCheckoutSessionEndpoint =
    "payments/v1/payments/create-checkout-session/";
const String createBillingPortalSessionEndpoint =
    "payments/v1/payments/create-billing-portal-session/";
const String subscriptionEndpoint = "payments/v1/payments/subscription/";
const String paymentAppSuccessReturnUrl = "attentionminder://payments/success";
const String paymentAppCancelReturnUrl = "attentionminder://payments/cancel";

// ============================================================================
// Result ENDPOINTS
// ============================================================================
const String getResultofAIBasedEndpoint =
    "assessment/v1/ai-assessment/score-history?is_assessment=true";
const String getManagementDashboardEndpoint =
    "assessment/v1/management/dashboard";
    const String getWeeklyDetailEndpoint =
    "assessment/v1/management/latest-week";
const String getResultofQuestionnaireEndpoint =
    "assessment/v1/self-assessment/result-history";

// ==================================== ========================================
// CONVENIENCE GETTERS (Combine base URL with endpoint)
// ============================================================================

// Authentication
String get loginUrl => baseUrl + loginEndpoint;

// Users
String get registrationUrl => baseUrl + registrationEndpoint;
String get userProfileUrl => baseUrl + getUserProfileEndpoint;
String get updateProfileUrl => baseUrl + updateProfileEndpoint;
String get passwordResetRequestUrl => baseUrl + passwordResetRequestEndpoint;
String get passwordResetOtpVerifyUrl =>
    baseUrl + passwordResetOtpVerifyEndpoint;
String get passwordResetChangeUrl => baseUrl + passwordResetChangeEndpoint;

// Assessment
String get questionUrl => baseUrl + getQuestionEndPoint;
String get saveQuestionUrl => baseUrl + saveQuestionEndPoint;
String get fetchResultUrl => baseUrl + fetchResultEndpoint;

// File Handler
String get getFilesUrl => baseUrl + getFilesEndpoint;
String get saveFeedbackUrl => baseUrl + saveFeedbackEndpoint;

// Attention Management
String get programDataUrl => baseUrl + getProgramDataEndpoint;
String get attentionAssessmentUrl => baseUrl + getAttentionAssessmentEndpoint;
String get submitAttentionAssessmentUrl =>
    baseUrl + submitAttentionAssessmentEndpoint;
String get dailySessionUrl => baseUrl + getDailySessionEndpoint;
String get completeSessionUrl => baseUrl + completeSessionEndpoint;
String get saveGoalsUrl => baseUrl + saveGoalsEndpoint;
String get progressDataUrl => baseUrl + getProgressDataEndpoint;
String get saveAiAssessmentScoreUrl => baseUrl + saveAiAssessmentScoreEndpoint;

// Articles
String get getArticlesUrl => baseUrl + getArticlesUrlEndpoint;
String get progressCardUrl => baseUrl + getprogressCardEndpoint;

// Payments
String get createCheckoutSessionUrl => baseUrl + createCheckoutSessionEndpoint;
String get createBillingPortalSessionUrl =>
    baseUrl + createBillingPortalSessionEndpoint;
String get subscriptionUrl => baseUrl + subscriptionEndpoint;

//Result
String get getResultofAiBasedUrl => baseUrl + getResultofAIBasedEndpoint;
String get getResultofQuestionnaireUrl =>
    baseUrl + getResultofQuestionnaireEndpoint;
String get getManagementDashboardUrl =>
    baseUrl + getManagementDashboardEndpoint;
    String get getweeklyDetailUrl=>
    baseUrl + getWeeklyDetailEndpoint;
