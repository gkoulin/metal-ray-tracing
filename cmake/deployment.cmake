# Get an application's deployment path
function(__deploy_get_app_path APP_NAME DEST)
  if(APPLE)
    set(_destination "$<TARGET_NAME_IF_EXISTS:${APP_NAME}>.app/Contents")
  else()
    set(_destination "$<TARGET_NAME_IF_EXISTS:${APP_NAME}>")
  endif()

  set(${DEST}
      "${_destination}"
      PARENT_SCOPE)
endfunction()

# Get an applications's resource path
function(__deploy_get_app_resource_path APP_NAME DEST)
  __deploy_get_app_path(${APP_NAME} _app_dir)
  set(_resource_dir "${_app_dir}/Resources")

  set(${DEST}
      "${_resource_dir}"
      PARENT_SCOPE)
endfunction()

# Install resource target to app resource directory
function(deploy_app_resource)
  cmake_parse_arguments(_args "" "APP_NAME" "TARGETS;FILES;DIRECTORY" ${ARGN})

  if(NOT _args_APP_NAME)
    message(FATAL_ERROR "APP_NAME must be set")
  endif()

  __deploy_get_app_resource_path(${_args_APP_NAME} _resource_dir)

  if(_args_TARGETS)
    install(
      TARGETS ${_args_TARGETS}
      COMPONENT ${APP_NAME}
      DESTINATION ${_resource_dir})
  elseif(_args_FILES)
    install(
      FILES ${_args_FILES}
      COMPONENT ${APP_NAME}
      DESTINATION ${_resource_dir})
  elseif(_args_DIRECTORY)
    install(
      DIRECTORY ${_args_DIRECTORY}
      COMPONENT ${APP_NAME}
      DESTINATION ${_resource_dir})
  endif()
endfunction()

# Install app
function(deploy_app APP_NAME)
  install(
    TARGETS ${APP_NAME}
    COMPONENT ${APP_NAME}
    BUNDLE DESTINATION "."
    RUNTIME DESTINATION ${APP_NAME})
endfunction()
