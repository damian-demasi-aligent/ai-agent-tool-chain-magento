#!/usr/bin/env bash
#
# Shared configuration for Claude Code hooks.
# All project-specific paths are centralised here — edit these when reusing
# the .claude/ directory in another Magento + React project.
#

# Vendor namespace used in app/code/<Vendor>/
export VENDOR_NAMESPACE="CountryCareGroup"

# React source root (relative to repo root)
export REACT_SRC="app/code/${VENDOR_NAMESPACE}/React/view/frontend/src/app"

# Vite build output directories (relative to repo root)
export REACT_BUILD_JS="app/code/${VENDOR_NAMESPACE}/React/view/frontend/web/js"
export REACT_BUILD_CSS="app/code/${VENDOR_NAMESPACE}/React/view/frontend/web/css"

# GraphQL sync-check paths
export GQL_SCHEMA_GLOB="app/code/${VENDOR_NAMESPACE}/*/etc/schema.graphqls"
export GQL_TEMPLATES_GLOB="${REACT_SRC}/AdobeProvider/GQL/*.ts"
export GQL_TYPES_FILE="${REACT_SRC}/types/ccgProvider.ts"
