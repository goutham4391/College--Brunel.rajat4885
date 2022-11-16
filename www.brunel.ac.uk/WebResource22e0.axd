/// <reference path="..\..\..\..\lib\typescript\defs\jquery\jquery.d.ts" />
/// <reference path="..\..\..\..\lib\typescript\defs\jquery.validation\jquery.validation.d.ts" />
var Contensis;
(function (Contensis) {
    var Mvc;
    (function (Mvc) {
        'use strict';
        var $j = jQuery;
        var Form = /** @class */ (function () {
            function Form(container, summary, action, method) {
                this.formInputSelector = 'input,textarea,select';
                this.formSummaryInnerCssSelector = '.contensis-form-summary-inner';
                // standard jQueryUI validation css classes
                this.validatorSummarySelector = "div.validation-summary-valid,div.validation-summary-invalid";
                this.shouldValidate = false;
                this.action = action;
                this.method = method;
                this.containerSelector = "#" + container;
                this.formSummarySelector = "." + summary;
                this.containerElement = $j(this.containerSelector);
                this.formSummaryElement = this.containerElement.find(this.formSummarySelector);
                this.formSummaryInnerElement = this.formSummaryElement.find(this.formSummaryInnerCssSelector);
                // listen for Submit and Reset buttons of our "form" 
                this.initializeEvents();
                // conditionally check for the existance of jQuery validation plugin
                // and only setup if it is loaded.
                this.initializeValidation();
            }
            /**
            * Attach event listeners for Submit and Reset buttons,
            * and prevent browser default for Form submission
            */
            Form.prototype.initializeEvents = function () {
                var _this = this;
                this.containerElement.find(':submit').click(function (e) {
                    _this.onFormSubmit();
                    e.preventDefault();
                });
                this.containerElement.find(':reset').click(function (e) {
                    _this.onFormReset();
                    e.preventDefault();
                });
            };
            /**
            * Conditionally check for the existance of jQuery validation plugin
            */
            Form.prototype.initializeValidation = function () {
                // check for the existance of the jQuery.validation library
                // before assuming we can validate the form
                if ($j.validator && $j.validator.unobtrusive) {
                    this.overrideJqueryValidation();
                    this.shouldValidate = true;
                    $j.validator.unobtrusive.parse(this.containerElement);
                    this.overrideJqueryValidationEvents();
                }
            };
            /**
            * Returns all form inputs contained within the Contensis Form
            * @returns {Array} All form elements within this container
            */
            Form.prototype.getFormInputs = function () {
                var formInputs = this.containerElement.find(this.formInputSelector);
                return formInputs;
            };
            /**
            * Event Handler for form submission, ensures validation and
            * serializes form data to perform a Http Post callback
            */
            Form.prototype.onFormSubmit = function () {
                var formInputs = this.getFormInputs(), postData;
                this.clearSummary();
                if (this.isFormValid(formInputs)) {
                    postData = formInputs.serialize();
                    if (this.shouldValidate) {
                        this.clearValidation();
                    }
                    this.postForm(postData);
                }
            };
            /**
            * Mimics the browser behaviour for clearing a <form> except
            * ContensisForms are using our custom container
            */
            Form.prototype.clearFormInputs = function () {
                this.containerElement
                    .find(':input')
                    .each(function (idx, elem) {
                    switch (elem.type) {
                        case 'password':
                        case 'text':
                        case 'textarea':
                        case 'file':
                        case 'select-one':
                            $j(elem).val('');
                            break;
                        case 'checkbox':
                        case 'radio':
                            elem.checked = false;
                    }
                });
            };
            /**
            * Resets jQuery validation state, and removes validation
            * DOM elements
            */
            Form.prototype.clearValidation = function () {
                // exit early if we dont have jQuery validation in scope
                if (!this.shouldValidate)
                    return null;
                var validator = this.getValidator();
                if (validator) {
                    validator.resetForm();
                }
                this.containerElement.find(".validation-summary-errors")
                    .addClass("validation-summary-valid")
                    .removeClass("validation-summary-errors")
                    .find("ul")
                    .empty();
                this.containerElement.find(".field-validation-error")
                    .addClass("field-validation-valid")
                    .removeClass("field-validation-error")
                    .removeData("unobtrusiveContainer")
                    .find(">*") // If we were using valmsg-replace, get the underlying error
                    .removeData("unobtrusiveContainer")
                    .empty();
            };
            /**
            * Event Handler for form reset.  Clears validation and
            * sets all form values to their original state.
            */
            Form.prototype.onFormReset = function () {
                this.clearFormInputs();
                this.clearValidation();
                this.clearSummary();
            };
            /**
            * Retrieves the Validation object from .data attribute
            * @returns {object} Validator jQuery Validator object
            */
            Form.prototype.getValidator = function () {
                var validator = this.containerElement.data("validator");
                return validator;
            };
            /**
            * Overrides default jQuery validation, and instead
            * of firing validate on the whole form, we validate
            * each individual form element within the container
            * @param {Array} inputs - All inputs within the Form
            * @returns {boolean} True if all form elements match their validation rule, otherwise false
            */
            Form.prototype.isFormValid = function (inputs) {
                var valid = true;
                if (this.shouldValidate) {
                    var validator = this.getValidator();
                    if (validator) {
                        valid = validator.form();
                    }
                }
                return valid;
            };
            /*
            * Clear Form Summary
            */
            Form.prototype.clearSummary = function () {
                this.formSummaryElement.hide();
                this.formSummaryInnerElement.empty();
            };
            /*
            * Perform the Http action with the seriaized form data
            * @param {string} postData The name value pairs of the Form data.
            */
            Form.prototype.postForm = function (postData) {
                var _this = this;
                var post = $j.ajax({
                    url: this.action,
                    data: postData,
                    processData: false,
                    type: this.method
                });
                post.done(function (result) {
                    if (result.success) {
                        _this.onFormPostSuccess(result);
                    }
                    else {
                        _this.onFormPostFail(result);
                    }
                });
                post.fail(function (error) {
                    _this.onFormPostException(error);
                });
            };
            /*
            * Response received from endpoint, so determine what action to take.
            * @param {Object} result The Form response returned by the server
            */
            Form.prototype.onFormPostSuccess = function (result) {
                if (result.action === 'DisplayMessage') {
                    this.displayMessage(result.message, true);
                }
                else if (result.action === 'Redirect') {
                    this.processRedirect(result);
                }
            };
            /*
            * Server given a handled error resonse, so output it in Form summary
            * @param {Object} ex The exception returned from the server
            */
            Form.prototype.onFormPostFail = function (response) {
                this.displayMessage(response.message, false);
            };
            /*
            * Server given an unhandled error resonse, so output it in Form summary
            * @param {Object} ex The exception returned from the server
            */
            Form.prototype.onFormPostException = function (ex) {
                this.displayMessage(ex.statusText, false);
            };
            /*
            * Display the message in Form Summary
            * @param {string} message The message to display
            * @param {boolean} success Toggles the css class on the Summary
            */
            Form.prototype.displayMessage = function (message, success) {
                this.formSummaryElement.show();
                this.formSummaryInnerElement.empty().append(message);
                if (success) {
                    this.formSummaryElement
                        .removeClass('validation-summary-invalid')
                        .addClass('validation-summary-valid');
                }
                else {
                    this.formSummaryElement
                        .removeClass('validation-summary-valid')
                        .addClass('validation-summary-invalid');
                }
            };
            /*
            * Allows the server to return a type of redirect, to mimic
            * a typical Html Form post to a different Url
            * @param {Object} response The form response object
            */
            Form.prototype.processRedirect = function (response) {
                var redirect = response.redirect;
                switch (redirect.method) {
                    case 'POST':
                        var postData = {};
                        if (typeof redirect.body === 'string') {
                            postData = this.queryStringToJson(redirect.body);
                        }
                        else if (typeof redirect.body === 'object') {
                            postData = redirect.body;
                        }
                        this.redirectPost(redirect.url, postData);
                        break;
                    default:// GET etc
                        this.displayMessage(response.message, true);
                        window.setTimeout(function () {
                            window.location = (redirect.url);
                        }, redirect.delay);
                        break;
                }
            };
            /*
            * Turn name value pairs into a Json object for use in building a Form
            * and performing Post to specified Url
            * @param {string} data The Form Post body returned from the server
            * @returns {Object} An object representing the Post data
            */
            Form.prototype.queryStringToJson = function (data) {
                var result = {}, pairs = data.split('&');
                pairs.forEach(function (pair) {
                    var kvp = pair.split('=');
                    result[kvp[0]] = decodeURIComponent(kvp[1] || '');
                });
                return JSON.parse(JSON.stringify(result));
            };
            /*
             * Build a temporary Form tag, populate a hidden field with
             * each of the field data returned from server, then Post
             * to specified Url.
             * @param {string} location The Url to form a Post to
             * @param {object} args An object representing all form data to post
             */
            Form.prototype.redirectPost = function (location, args) {
                var form = '';
                $j.each(args, function (key, value) {
                    value = value.split("\"").join("\"");
                    form += '<input type="hidden" name="' + key + '" value="' + value + '">';
                });
                $j('<form action="' + location + '" method="POST">' + form + '</form>').appendTo($j(document.body)).submit();
            };
            /**
            * There are several functions from jQuery Validation and
            * jQuery Validation.unobtrusive that are hard coded
            * to work with a <form> element, so we override them
            * to use a css class selector instead.
            */
            Form.prototype.overrideJqueryValidation = function () {
                function escapeAttributeValue(value) {
                    // As mentioned on http://api.jquery.com/category/selectors/
                    return value.replace(/([!"#$%&'()*+,./:;<=>?@\[\\\]^`{|}~])/g, "\\$1");
                }
                function onError(error, inputElement) {
                    var container = $j(this).find("[data-valmsg-for='" + escapeAttributeValue(inputElement[0].name) + "']"), replaceAttrValue = container.attr("data-valmsg-replace"), replace = replaceAttrValue ? $j.parseJSON(replaceAttrValue) !== false : null;
                    container.removeClass("field-validation-valid").addClass("field-validation-error");
                    error.data("unobtrusiveContainer", container);
                    if (replace) {
                        container.empty();
                        error.removeClass("input-validation-error").appendTo(container);
                    }
                    else {
                        error.hide();
                    }
                }
                function onErrors(event, validator) {
                    var container = $j(this).find("[data-valmsg-summary=true]"), list = container.find("ul");
                    if (list && list.length && validator.errorList.length) {
                        list.empty();
                        container.addClass("validation-summary-errors").removeClass("validation-summary-valid");
                        $j.each(validator.errorList, function () {
                            $j("<li />").html(this.message).appendTo(list);
                        });
                    }
                }
                function onSuccess(error) {
                    var container = error.data("unobtrusiveContainer"), replaceAttrValue = container.attr("data-valmsg-replace"), replace = replaceAttrValue ? $j.parseJSON(replaceAttrValue) : null;
                    if (container) {
                        container.addClass("field-validation-valid").removeClass("field-validation-error");
                        error.removeData("unobtrusiveContainer");
                        if (replace) {
                            container.empty();
                        }
                    }
                }
                // overrides: jQuery.validate staticRules
                // jQuery validate is hard coded to look for element forms
                $j.validator.staticRules = function (element) {
                    var rules = {};
                    var form = $j(element).parents('.contensis-form')[0];
                    var validator = $j.data(form, 'validator');
                    if (validator.settings.rules) {
                        rules = $j.validator.normalizeRule(validator.settings.rules[element.name]) || {};
                    }
                    return rules;
                };
                // overrides: jQuery.validate.unobtrusive parseElement
                // jQuery validate is hard coded to look for element forms
                $j.validator.unobtrusive.parseElement = function (element, skipAttach) {
                    var $element = $(element), form = $element.parents('.contensis-form')[0], valInfo, rules, messages;
                    if (!form) {
                        return;
                    }
                    valInfo = $j.validator.unobtrusive.validationInfo(form);
                    valInfo.options.rules[element.name] = rules = {};
                    valInfo.options.messages[element.name] = messages = {};
                    $.each(this.adapters, function () {
                        var prefix = "data-val-" + this.name, message = $element.attr(prefix), paramValues = {};
                        if (message !== undefined) {
                            prefix += "-";
                            $.each(this.params, function () {
                                paramValues[this] = $element.attr(prefix + this);
                            });
                            this.adapt({
                                element: element,
                                form: form,
                                message: message,
                                params: paramValues,
                                rules: rules,
                                messages: messages
                            });
                        }
                    });
                    $.extend(rules, { "__dummy__": true });
                    if (!skipAttach) {
                        valInfo.attachValidation();
                    }
                };
                // overrides: jQuery.validate.unobtrusive parse
                // jQuery validate is hard coded to look for element forms
                $j.validator.unobtrusive.parse = function (selector) {
                    // $forms includes all forms in selector's DOM hierarchy (parent, children and self) that have at least one
                    // element with data-val=true
                    var $selector = $(selector), $forms = $selector.parents()
                        .addBack()
                        .filter('.contensis-form')
                        .add($selector.find('.contensis-form'))
                        .has("[data-val=true]");
                    $selector.find("[data-val=true]").each(function () {
                        $j.validator.unobtrusive.parseElement(this, true);
                    });
                    $forms.each(function () {
                        var info = $j.validator.unobtrusive.validationInfo(this);
                        if (info) {
                            info.attachValidation();
                        }
                    });
                };
                $j.validator.unobtrusive.validationInfo = function (form) {
                    var $form = $(form), 
                    // ReSharper disable once InconsistentNaming, just copied jQuery Validation function body
                    data_validation = 'unobtrusiveValidation', result = $form.data(data_validation), 
                    // ReSharper disable once AssignedValueIsNeverUsed, used within jQuery Validation context
                    onResetProxy = $j.proxy(this.onReset, form), defaultOptions = $j.validator.unobtrusive.options || {}, 
                    // ReSharper disable once AssignedValueIsNeverUsed, used within jQuery Validation context
                    execInContext = function (name, args) {
                        var func = defaultOptions[name];
                        func && $.isFunction(func) && func.apply(form, args);
                    };
                    if (!result) {
                        result = {
                            options: {
                                // options structure passed to jQuery Validate's validate() method
                                errorClass: defaultOptions.errorClass || "input-validation-error",
                                errorElement: defaultOptions.errorElement || "span",
                                errorPlacement: function () {
                                    onError.apply(form, arguments);
                                    execInContext("errorPlacement", arguments);
                                },
                                invalidHandler: function () {
                                    onErrors.apply(form, arguments);
                                    execInContext("invalidHandler", arguments);
                                },
                                messages: {},
                                rules: {},
                                success: function () {
                                    onSuccess.apply(form, arguments);
                                    execInContext("success", arguments);
                                }
                            },
                            attachValidation: function () {
                                $form.validate(this.options);
                            },
                            validate: function () {
                                $form.validate();
                                return $form.valid();
                            }
                        };
                        $form.data(data_validation, result);
                    }
                    return result;
                };
            };
            /**
            * jQuery.validate binds events to the <form> object on initialization
            * with a callback that expects a <form> element, so we unbind them
            * and add our own delegate, which will use Css Selector
            */
            Form.prototype.overrideJqueryValidationEvents = function () {
                $j(this.containerElement)
                    .unbind('focusin focusout keyup')
                    .unbind('click');
                function delegate(event) {
                    var form = $j(this[0]).parents('.contensis-form')[0], validator = $j.data(form, "validator"), eventType = "on" + event.type.replace(/^validate/, "");
                    if (validator.settings[eventType]) {
                        validator.settings[eventType].call(validator, this[0], event);
                    }
                }
                this.containerElement.validateDelegate(":text, [type='password'], [type='file'], select, textarea, " +
                    "[type='number'], [type='search'] ,[type='tel'], [type='url'], " +
                    "[type='email'], [type='datetime'], [type='date'], [type='month'], " +
                    "[type='week'], [type='time'], [type='datetime-local'], " +
                    "[type='range'], [type='color'] ", "focusin focusout keyup", delegate)
                    .validateDelegate("[type='radio'], [type='checkbox'], select, option", "click", delegate);
            };
            return Form;
        }());
        Mvc.Form = Form;
    })(Mvc = Contensis.Mvc || (Contensis.Mvc = {}));
})(Contensis || (Contensis = {}));
//# sourceMappingURL=Contensis.ContensisForm.js.map