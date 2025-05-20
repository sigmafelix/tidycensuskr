## R6 based various API authentication factory
## classes
#' @title Authentication
#' @description Authentication class for API authentication
#' @export
#' @importFrom R6 R6Class
#' @importFrom httr authenticate
#' @importFrom httr config
#' @importFrom httr add_headers
#' @importFrom httr oauth_app
#' @importFrom httr oauth2.0_token
#' @importFrom httr oauth2.0_authorize_url
#' @importFrom httr oauth2.0_access_token
#'
#' @description
#' The `Authentication` class is an R6 class that provides a framework for
#' handling API authentication. It supports various authentication methods,
#' including basic authentication, OAuth 2.0, and custom authentication.
#' #' @details
#' The `Authentication` class is designed to be extended by other classes
#' that implement specific authentication methods. It provides a common
#' interface for authentication, allowing users to easily switch between
#' different authentication methods.
#' #' @section Methods:
#' \describe{
#' \item{\code{initialize()}}{
#'   Initializes the authentication object.
#'  }
#' \item{\code{authenticate()}}{
#'  Authenticates the user using the specified authentication method.
#' }
#' \item{\code{get_token()}}{
#' Retrieves the authentication token.
#' }
#' \item{\code{set_token()}}{
#' Sets the authentication token.
#' }
#' \item{\code{get_headers()}}{
#' Retrieves the headers for the authentication request.
#' }
#' \item{\code{set_headers()}}{
#' Sets the headers for the authentication request.
#' }
#' \item{\code{get_config()}}{
#' Retrieves the configuration for the authentication request.
#' }
#' \item{\code{set_config()}}{
#' Sets the configuration for the authentication request.
#' }
#' \item{\code{get_url()}}{
#' Retrieves the URL for the authentication request.
#' }
#' \item{\code{set_url()}}{
#' Sets the URL for the authentication request.
#' }
#' \item{\code{get_client_id()}}{
#' Retrieves the client ID for the authentication request.
#' }
#' \item{\code{set_client_id()}}{
#' Sets the client ID for the authentication request.
#' }
#' \item{\code{get_client_secret()}}{
#' Retrieves the client secret for the authentication request.
#' }
#' \item{\code{set_client_secret()}}{
#' Sets the client secret for the authentication request.
#' }
#' \item{\code{get_scope()}}{
#' Retrieves the scope for the authentication request.
#' }
#' \item{\code{set_scope()}}{
#' Sets the scope for the authentication request.
#' }
#' \item{\code{get_redirect_uri()}}{
#' Retrieves the redirect URI for the authentication request.
#' }
#' \item{\code{set_redirect_uri()}}{
#' Sets the redirect URI for the authentication request.
#' }
#' \item{\code{get_authorization_code()}}{
#' Retrieves the authorization code for the authentication request.
#' }
#' \item{\code{set_authorization_code()}}{
#' Sets the authorization code for the authentication request.
#' }
#' \item{\code{get_access_token()}}{
#' Retrieves the access token for the authentication request.
#' }
#' \item{\code{set_access_token()}}{
#' Sets the access token for the authentication request.
#' }
#' \item{\code{get_refresh_token()}}{
#' Retrieves the refresh token for the authentication request.
#' }
#' \item{\code{set_refresh_token()}}{
#' Sets the refresh token for the authentication request.
#' }
#' \item{\code{get_expires_in()}}{
#' Retrieves the expiration time for the authentication token.
#' }
#' \item{\code{set_expires_in()}}{
#' Sets the expiration time for the authentication token.
#' }
#' \item{\code{get_token_type()}}{
#' Retrieves the token type for the authentication request.
#' }
#' \item{\code{set_token_type()}}{
#' Sets the token type for the authentication request.
#' }
#' \item{\code{get_state()}}{
#' Retrieves the state for the authentication request.
#' }
#' \item{\code{set_state()}}{
#' Sets the state for the authentication request.
#' }
#' \item{\code{get_error()}}{
#' Retrieves the error message for the authentication request.
#' }
#' \item{\code{set_error()}}{
#'  
#' Sets the error message for the authentication request.
#' }
#' \item{\code{get_error_description()}}{
#' Retrieves the error description for the authentication request.
#' }
#' \item{\code{set_error_description()}}{
#' Sets the error description for the authentication request.
#' }
#' \item{\code{get_error_uri()}}{
#' Retrieves the error URI for the authentication request.
#' }
#' \item{\code{set_error_uri()}}{
#' Sets the error URI for the authentication request.
#' }
#' \item{\code{get_error_code()}}{
#' Retrieves the error code for the authentication request.
#' }
#' \item{\code{set_error_code()}}{
#' Sets the error code for the authentication request.
#' }
#' \item{\code{get_error_description()}}{
#' Retrieves the error description for the authentication request.
#' }
#' \item{\code{set_error_description()}}{
#' Sets the error description for the authentication request.
#' }
#'
#' @return An instance of the `Authentication` class.
#'
#' @examples
#' auth <- Authentication$new()
#' auth$set_client_id("your_client_id")
#' auth$set_client_secret("your_client_secret")
#' auth$set_scope("your_scope")
#' auth$set_redirect_uri("your_redirect_uri")
#' auth$set_authorization_code("your_authorization_code")
#' auth$set_access_token("your_access_token")
#' auth$set_refresh_token("your_refresh_token")
#' auth$set_expires_in(3600)
#' auth$set_token_type("Bearer")
#' auth$set_state("your_state")
#' auth$set_error("your_error")
#' auth$set_error_description("your_error_description")
#' auth$set_error_uri("your_error_uri")
#' 
#' 
#' auth$set_error_code("your_error_code")
#' auth$set_error_description("your_error_description")
#' auth$get_client_id()
#' auth$get_client_secret()
#' auth$get_scope()
#' auth$get_redirect_uri()
#' auth$get_authorization_code()
#' auth$get_access_token()
#' auth$get_refresh_token()
#'
# main code
Authentication <- R6::R6Class(
  "Authentication",
  public = list(
    client_id = NULL,
    client_secret = NULL,
    scope = NULL,
    redirect_uri = NULL,
    authorization_code = NULL,
    access_token = NULL,
    refresh_token = NULL,
    expires_in = NULL,
    token_type = NULL,
    state = NULL,
    error = NULL,
    error_description = NULL,
    error_uri = NULL,
    error_code = NULL,
    error_description = NULL,
    initialize = function(client_id = NULL, client_secret = NULL, scope = NULL,
                          redirect_uri = NULL, authorization_code = NULL,
                          access_token = NULL, refresh_token = NULL,
                          expires_in = NULL, token_type = NULL,
                          state = NULL, error = NULL,
                          error_description = NULL, error_uri = NULL,
                          error_code = NULL) {
      self$client_id <- client_id
      self$client_secret <- client_secret
      self$scope <- scope
      self$redirect_uri <- redirect_uri
      self$authorization_code <- authorization_code
      self$access_token <- access_token
      self$refresh_token <- refresh_token
      self$expires_in <- expires_in
      self$token_type <- token_type
      self$state <- state
      self$error <- error
      self$error_description <- error_description
      self$error_uri <- error_uri
      self$error_code <- error_code
    },
    authenticate = function() {
      stop("authenticate() method not implemented")
    },
    get_token = function() {
      return(self$access_token)
    },
    set_token = function(token) {
      self$access_token <- token
    },
    get_headers = function() {
      return(list(Authorization = paste("Bearer", self$access_token)))
    },
    set_headers = function(headers) {
      self$headers <- headers
    },
    get_config = function() {
      return(list(client_id = self$client_id,
                  client_secret = self$client_secret,
                  scope = self$scope,
                  redirect_uri = self$redirect_uri))
    },
    set_config = function(config) {
      self$client_id <- config$client_id
      self$client_secret <- config$client_secret
      self$scope <- config$scope
      self$redirect_uri <- config$redirect_uri
    },
    get_url = function() {
      return(self$url)
    },
    set_url = function(url) {
      self$url <- url
    },
    get_client_id = function() {
      return(self$client_id)
    },
    set_client_id = function(client_id) {
      self$client_id <- client_id
    },
    get_client_secret = function() {
      return(self$client_secret)
    },
    set_client_secret = function(client_secret) {
      self$client_secret <- client_secret
    },
    get_scope = function() {
      return(self$scope)
    },
    set_scope = function(scope) {
      self$scope <- scope
    },
    get_redirect_uri = function() {
      return(self$redirect_uri)
    },
    set_redirect_uri = function(redirect_uri) {
      self$redirect_uri <- redirect_uri
    },
    get_authorization_code = function() {
      return(self$authorization_code)
    },
    set_authorization_code = function(authorization_code) {
      self$authorization_code <- authorization_code
    },
    get_access_token = function() {
      return(self$access_token)
    },
    set_access_token = function(access_token) {
      self$access_token <- access_token
    },
    get_refresh_token = function() {
      return(self$refresh_token)
    },
    set_refresh_token = function(refresh_token) {
      self$refresh_token <- refresh_token
    },
    get_expires_in = function() {
      return(self$expires_in)
    },
    set_expires_in = function(expires_in) {
      self$expires_in <- expires_in
    },
    get_token_type = function() {
      return(self$token_type)
    },
    set_token_type = function(token_type) {
      self$token_type <- token_type
    },
    get_state = function() {
      return(self$state)
    },
    set_state = function(state) {
      self$state <- state
    },
    get_error = function() {
      return(self$error)
    },
    set_error = function(error) {
      self$error <- error
    },
    get_error_description = function() {
      return(self$error_description)
    },
    set_error_description = function(error_description) {
      self$error_description <- error_description
    },
    get_error_uri = function() {
      return(self$error_uri)
    },
    set_error_uri = function(error_uri) {
      self$error_uri <- error_uri
    },
    get_error_code = function() {
      return(self$error_code)
    },
    set_error_code = function(error_code) {
      self$error_code <- error_code
    },
    get_error_description = function() {
      return(self$error_description)
    },
    set_error_description = function(error_description) {
      self$error_description <- error_description
    }
    )
)




