;;; as3-simple-mode.el --- Major mode for editing ActionScript 3 code.

;; Copyright (C) 2011

;; Author: Stefan A. van der Meer <stefanvandermeer@gmail.com>
;; Version: 1
;; Date: 2011-09-16
;; Keywords: languages, actionscript

;; This is free software; you can redistribute it and/or modify it under the
;; terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
;; A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; as3-mode is a simple major mode for editing ActionScript 3 code, deriving
;; from js-mode (js.el, included with Emacs). js-mode already does the right
;; thing with regards to indentation for AS3 code (not surprising considering
;; their similarity), so this mode only adds some AS3-specific fontification.
;;
;; Some alternative modes for AS3 you might want to look at:
;;
;; - as3-mode.el by Aemon Cannon (https://github.com/aemoncannon/as3-mode/):
;;   Depends on flyparse for live parsing, making it more heavyweight, but it
;;   can offer more feedback. Has indentation bugs (on single-line block
;;   statements without braces).
;;
;; - ecmascript-mode.el by David Lindquist (see EmacsWiki.org)
;;   Compatible with all ECMAScript-derived languages including AS3, but has
;;   font/indent bugs (fontifies keywords in comments, indents "for each" blocks
;;   wrong, etc).
;;
;; - actionscript-mode.el by Austin Haas (see EmacsWiki.org)
;;   More lightweight than as3-mode, but defines its own set of faces rather
;;   than using standard font-lock faces. Borrows indentation from as3-mode,
;;   along with the bugs.
;;
;; All of them have some issues that I found annoying, hence this mode. It aims
;; to avoid indentation issues by depending on cc-mode, made easy because
;; js-mode already configures cc-mode's indentation the way we need it.
;;
;; Some fontification of built-ins is borrowed from ecmascript-mode.el.
;;
;; Tested only on Emacs 24.
;;
;; Known issues:
;;
;; - Some parts of js-mode are used that are meant to be private (prefixed with
;;   "js--").
;;
;; - Certain syntax for namespace usage is not fontified
;;   (e.g., foo.mx_internal::barField.baz)
;;
;; - Identifiers in package and class declarations are not fontified yet.
;;
;; - Function definitions that do not specify a return type are underlined as
;;   warning, even if you are not compiling in strict mode and hence do not
;;   require return types.
;;
;; - AS3-specific builtins are not fontified, even very common ones.
;;
;;; Code:

(require 'js)
(require 'cc-mode)


(defgroup as3-simple nil
  "Major mode for editing ActionScript 3 code."
  :group 'languages
  :prefix "as3-simple-")


(defconst as3--font-lock-additions
  (list
   (list
    (js--regexp-opt-symbol
     '("dynamic" "use\snamespace"
       "internal" "override" "set" "get"
       "as" "is"
       "include"))
    1 font-lock-keyword-face)

   ;; Fontify rest parameters keyword
   '("\\(\\.\\.\\.\\)"
     (1 font-lock-keyword-face))

   ;; Fontify type identifiers after a semicolon or is/as/instanceof
   '("\\(?:\\:\\|\\(?:\\(?:as\\|is\\|instanceof\\|new\\)\\s-+\\)\\)\s*\\(\\w+\\)"
     (1 font-lock-type-face))

   ;; Fontify function name and return type
   '("\\<\\(function\\)\\>\\(?:\\(?:\\s-+\\(?:\\w+\\)\\)*\\s-+\\(\\sw+\\)\\)?\s*(.*)\\s-+\\:\s*\\(\\w+\\|\\*\\)+"
     (1 font-lock-keyword-face t)
     (2 font-lock-function-name-face nil t)
     (3 font-lock-type-face t))

   ;; Underline common mistake of forgetting to define a function's return type
   '("\\<function\\>.*(.*)\\(\\s-+{\\)"
     (1 '(:underline "red") t))

   ;; Variable declarations
   '("\\<\\(var\\|const\\)\\>\\(?:\\s-+\\(\\sw+\\)\\)?"
     (1 font-lock-keyword-face t)
     (2 font-lock-variable-name-face nil t))

   ;; Basic builtin list from ecmascript-mode.el for non-AS3-specific classes
   (list (concat
          "\\."
          (regexp-opt
           '(;; Properties of the Object prototype object
             "hasOwnProperty" "isPrototypeOf" "propertyIsEnumerable"
             "toLocaleString" "toString" "valueOf"
             ;; Properties of the Function prototype object
             "apply" "call"
             ;; Properties of the Array prototype object
             "concat" "join" "pop" "push" "reverse" "shift" "slice" "sort"
             "splice" "unshift"
             ;; Properties of the String prototype object
             "charAt" "charCodeAt" "fromCharCode" "indexOf" "lastIndexOf"
             "localeCompare" "match" "replace" "search" "split" "substring"
             "toLocaleLowerCase" "toLocaleUpperCase" "toLowerCase"
             "toUpperCase"
             ;; Properties of the Number prototype object
             "toExponential" "toFixed" "toPrecision"
             ;; Properties of the Date prototype object
             "getDate" "getDay" "getFullYear" "getHours" "getMilliseconds"
             "getMinutes" "getMonth" "getSeconds" "getTime"
             "getTimezoneOffset" "getUTCDate" "getUTCDay" "getUTCFullYear"
             "getUTCHours" "getUTCMilliseconds" "getUTCMinutes" "getUTCMonth"
             "getUTCSeconds" "setDate" "setFullYear" "setHours"
             "setMilliseconds" "setMinutes" "setMonth" "setSeconds" "setTime"
             "setUTCDate" "setUTCFullYear" "setUTCHours" "setUTCMilliseconds"
             "setUTCMinutes" "setUTCMonth" "setUTCSeconds" "toDateString"
             "toLocaleDateString" "toLocaleString" "toLocaleTimeString"
             "toTimeString" "toUTCString"
             ;; Properties of the RegExp prototype object
             "exec" "test"
             ) t)
          "\\>")
         '(1 font-lock-builtin-face))
   ))


(defconst as3--font-lock-keywords
  (append js--font-lock-keywords-1
          js--font-lock-keywords-2
          ;; Exclude level 3, as it is primarily JS framework related stuff
          ;;js--font-lock-keywords-3
          as3--font-lock-additions
          )
  "Font lock keywords for `js-mode'.  See `font-lock-keywords'.")

(define-derived-mode as3-simple-mode js-mode "AS3s" "AS3 simple mode"
  (set (make-local-variable 'font-lock-defaults)
       (list as3--font-lock-keywords))

  ;; Disable js-mode's auto-indent on semicolon etc
  (use-local-map (make-sparse-keymap)))


(provide 'as3-simple-mode)
;;; as3-simple-mode.el ends here
