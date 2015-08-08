odoo.define('web_editor.rte.summernote', function (require) {
'use strict';

var core = require('web.core');
var ajax = require('web.ajax');
var base = require('web_editor.base');
var widgets = require('web_editor.widget');
var rte = require('web_editor.rte');

var QWeb = core.qweb;
var _t = core._t;

//////////////////////////////////////////////////////////////////////////////////////////////////////////

ajax.jsonRpc('/web/dataset/call', 'call', {
    'model': 'ir.ui.view',
    'method': 'read_template',
    'args': ['web_editor.colorpicker', base.get_context()]
}).done(function (data) {
    QWeb.add_template(data);
});

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Summernote Lib (neek change to make accessible: method and object) */

var dom = $.summernote.core.dom;
var range = $.summernote.core.range;
var eventHandler = $.summernote.eventHandler;
var renderer = $.summernote.renderer;
var options = $.summernote.options;

var tplButton = renderer.getTemplate().button;
var tplIconButton = renderer.getTemplate().iconButton;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* update and change the popovers content, and add history button */

var fn_createPalette = renderer.createPalette;
renderer.createPalette = function ($container, options) {
    fn_createPalette.call(this, $container, options);

    if (!QWeb.has_template('web_editor.colorpicker')) {
        return;
    }

    var $color = $container.find('.note-color');
    var html = QWeb.render('web_editor.colorpicker');
    $color.find('.note-color-palette').prepend(html);
    var $bg = $color.find('.colorpicker:first button');
    var $fore = $color.find('.colorpicker:last button');

    $bg.each(function () { $(this).attr('data-event', 'backColor').attr('data-value', $(this).attr('class')); });
    $fore.each(function () { $(this).attr('data-event', 'foreColor').attr('data-value', $(this).attr('class').replace(/bg-/, 'text-')); });
};

var fn_tplPopovers = renderer.tplPopovers;
renderer.tplPopovers = function (lang, options) {
    var $popover = $(fn_tplPopovers.call(this, lang, options));

    var $imagePopover = $popover.find('.note-image-popover');
    var $linkPopover = $popover.find('.note-link-popover');
    var $airPopover = $popover.find('.note-air-popover');

    if (window === window.top) {
        $popover.children().addClass("hidden-xs");
    }

    //////////////// image popover

    // add center button for images
    var $centerbutton = $(tplIconButton('fa fa-align-center', {
            title: _t('Center'),
            event: 'floatMe',
            value: 'center'
        })).insertAfter($imagePopover.find('[data-event="floatMe"][data-value="left"]'));
    $imagePopover.find('button[data-event="removeMedia"]').parent().remove();
    $imagePopover.find('button[data-event="floatMe"][data-value="none"]').remove();

    var $alt = $('<div class="btn-group"/>');
    $alt.prependTo($imagePopover.find('.popover-content'));
    $alt.append('<button class="btn btn-default btn-sm btn-small" data-event="alt"><strong>Alt: </strong><span class="o_image_alt"></span></button>');

    // padding button
    var $padding = $('<div class="btn-group"/>');
    $padding.insertBefore($imagePopover.find('.btn-group:first'));
    var $button = $(tplIconButton('fa fa-plus-square-o', {
            title: _t('Padding'),
            dropdown: true
        })).appendTo($padding);
    var $ul = $('<ul class="dropdown-menu"/>').insertAfter($button);
    $ul.append('<li><a data-event="padding" href="#" data-value="">'+_t('None')+'</a></li>');
    $ul.append('<li><a data-event="padding" href="#" data-value="small">'+_t('Small')+'</a></li>');
    $ul.append('<li><a data-event="padding" href="#" data-value="medium">'+_t('Medium')+'</a></li>');
    $ul.append('<li><a data-event="padding" href="#" data-value="large">'+_t('Large')+'</a></li>');
    $ul.append('<li><a data-event="padding" href="#" data-value="xl">'+_t('Xl')+'</a></li>');

    // circle, boxed... options became toggled
    $imagePopover.find('[data-event="imageShape"]:not([data-value])').remove();
    var $button = $(tplIconButton('fa fa-sun-o', {
            title: _t('Shadow'),
            event: 'imageShape',
            value: 'shadow'
        })).insertAfter($imagePopover.find('[data-event="imageShape"][data-value="img-circle"]'));

    // add spin for fa
    var $spin = $('<div class="btn-group hidden only_fa"/>').insertAfter($button.parent());
    $(tplIconButton('fa fa-refresh', {
            title: _t('Spin'),
            event: 'imageShape',
            value: 'fa-spin'
        })).appendTo($spin);

    // resize for fa
    var $resizefa = $('<div class="btn-group hidden only_fa"/>')
        .insertAfter($imagePopover.find('.btn-group:has([data-event="resize"])'));
    for (var size=1; size<=5; size++) {
        $(tplButton('<span class="note-fontsize-10">'+size+'x</span>', {
          title: size+"x",
          event: 'resizefa',
          value: size+''
        })).appendTo($resizefa);
    }
    var $colorfa = $airPopover.find('.note-color').clone();
    $colorfa.find(".btn-group:first").remove();
    $colorfa.find("ul.dropdown-menu").css('min-width', '172px');
    $colorfa.find('button[data-event="color"]').attr('data-value', '{"foreColor": "#f00"}')
        .find("i").css({'background': '', 'color': '#f00'});
    $resizefa.after($colorfa);

    // show dialog box and delete
    var $imageprop = $('<div class="btn-group"/>');
    $imageprop.appendTo($imagePopover.find('.popover-content'));
    $(tplIconButton('fa fa-picture-o', {
            title: _t('Edit'),
            event: 'showImageDialog'
        })).appendTo($imageprop);
    $(tplIconButton('fa fa-trash-o', {
            title: _t('Remove'),
            event: 'delete'
        })).appendTo($imageprop);

    $imagePopover.find('.popover-content').append($airPopover.find(".note-history").clone());

    $imagePopover.find('[data-event="showImageDialog"]').before($airPopover.find('[data-event="showLinkDialog"]').clone());
    
    //////////////// link popover

    $linkPopover.find('.popover-content').append($airPopover.find(".note-history").clone());

    $linkPopover.find('button[data-event="showLinkDialog"] i').attr("class", "fa fa-link");
    $linkPopover.find('button[data-event="unlink"]').before($airPopover.find('button[data-event="showImageDialog"]').clone());

    //////////////// text/air popover

    //// highlight the text format
    $airPopover.find('.note-style').on('mousedown', function () {
        var $format = $airPopover.find('[data-event="formatBlock"]');
        var node = range.create().sc;
        var formats = $format.map(function () { return $(this).data("value"); }).get();
        while (node && (!node.tagName || (!node.tagName || formats.indexOf(node.tagName.toLowerCase()) === -1))) {
            node = node.parentNode;
        }
        $format.parent().removeClass('active');
        $format.filter('[data-value="'+(node ? node.tagName.toLowerCase() : "p")+'"]')
            .parent().addClass("active");
    });

    //////////////// tooltip

    $airPopover.add($linkPopover).add($imagePopover).find("button")
        .tooltip('destroy')
        .tooltip({
            container: 'body',
            trigger: 'hover',
            placement: 'bottom'
        }).on('click', function () {$(this).tooltip('hide');});

    return $popover;
};

var fn_boutton_update = eventHandler.popover.button.update;
eventHandler.popover.button.update = function ($container, oStyle) {
    // stop animation when edit content
    var previous = $(".note-control-selection").data('target');
    if (previous) {
        $(previous).css({"-webkit-animation-play-state": "", "animation-play-state": "", "-webkit-transition": "", "transition": "", "-webkit-animation": "", "animation": ""});
    }
    if (oStyle.image) {
        $(oStyle.image).css({"-webkit-animation": "none", "animation": "none"});
    }
    // end

    fn_boutton_update.call(this, $container, oStyle);

    $container.find('.note-color').removeClass("hidden");

    if (oStyle.image) {
        $container.find('[data-event]').parent().removeClass("active");

        $container.find('a[data-event="padding"][data-value="small"]').parent().toggleClass("active", $(oStyle.image).hasClass("padding-small"));
        $container.find('a[data-event="padding"][data-value="medium"]').parent().toggleClass("active", $(oStyle.image).hasClass("padding-medium"));
        $container.find('a[data-event="padding"][data-value="large"]').parent().toggleClass("active", $(oStyle.image).hasClass("padding-large"));
        $container.find('a[data-event="padding"][data-value="xl"]').parent().toggleClass("active", $(oStyle.image).hasClass("padding-xl"));
        $container.find('a[data-event="padding"][data-value=""]').parent().toggleClass("active", !$container.find('.active a[data-event="padding"]').length);

        if (dom.isImgFont(oStyle.image)) {

            $container.find('.btn-group:not(.only_fa):has(button[data-event="resize"],button[data-event="imageShape"])').addClass("hidden");
            $container.find('.only_fa').removeClass("hidden");
            $container.find('button[data-event="resizefa"][data-value="2"]').toggleClass("active", $(oStyle.image).hasClass("fa-2x"));
            $container.find('button[data-event="resizefa"][data-value="3"]').toggleClass("active", $(oStyle.image).hasClass("fa-3x"));
            $container.find('button[data-event="resizefa"][data-value="4"]').toggleClass("active", $(oStyle.image).hasClass("fa-4x"));
            $container.find('button[data-event="resizefa"][data-value="5"]').toggleClass("active", $(oStyle.image).hasClass("fa-5x"));
            $container.find('button[data-event="resizefa"][data-value="1"]').toggleClass("active", !$container.find('.active[data-event="resizefa"]').length);

            $container.find('button[data-event="imageShape"][data-value="fa-spin"]').toggleClass("active", $(oStyle.image).hasClass("fa-spin"));

        } else {

            $container.find('.hidden:not(.only_fa)').removeClass("hidden");
            $container.find('.only_fa').addClass("hidden");
            var width = ($(oStyle.image).attr('style') || '').match(/(^|;|\s)width:\s*([0-9]+%)/);
            if (width) {
                width = width[2];
            }
            $container.find('button[data-event="resize"][data-value="1"]').toggleClass("active", width === "100%");
            $container.find('button[data-event="resize"][data-value="0.5"]').toggleClass("active", width === "50%");
            $container.find('button[data-event="resize"][data-value="0.25"]').toggleClass("active", width === "25%");

            $container.find('button[data-event="imageShape"][data-value="shadow"]').toggleClass("active", $(oStyle.image).hasClass("shadow"));

            if (!$(oStyle.image).is("img")) {
                $container.find('.btn-group:has(button[data-event="imageShape"])').addClass("hidden");
            }

            $container.find('.note-color').addClass("hidden");

        }

        $container.find('button[data-event="floatMe"][data-value="left"]').toggleClass("active", $(oStyle.image).hasClass("pull-left"));
        $container.find('button[data-event="floatMe"][data-value="center"]').toggleClass("active", $(oStyle.image).hasClass("center-block"));
        $container.find('button[data-event="floatMe"][data-value="right"]').toggleClass("active", $(oStyle.image).hasClass("pull-right"));

        $(oStyle.image).trigger('attributes_change');
    }
};

var fn_popover_update = eventHandler.popover.update;
eventHandler.popover.update = function ($popover, oStyle, isAirMode) {
    var $imagePopover = $popover.find('.note-image-popover');
    var $linkPopover = $popover.find('.note-link-popover');
    var $airPopover = $popover.find('.note-air-popover');

    fn_popover_update.call(this, $popover, oStyle, isAirMode);

    if (!isAirMode || $(oStyle.range.sc).closest('[data-oe-model]:not([data-oe-model="ir.ui.view"]):not([data-oe-type="html"])').length) {
        $imagePopover.hide();
        $linkPopover.hide();
        $airPopover.hide();
        return;
    }

    if (oStyle.image) {
        if (oStyle.image.parentNode.className.match(/(^|\s)media_iframe_video(\s|$)/i)) {
            oStyle.image = oStyle.image.parentNode;
        }
        var alt =  $(oStyle.image).attr("alt");

        $imagePopover.find('.o_image_alt').text( (alt || "").replace(/&quot;/g, '"') ).parent().toggle(oStyle.image.tagName === "IMG");
        $imagePopover.show();

        range.createFromNode(dom.firstChild(oStyle.image)).select();
    } else {
        $(".note-control-selection").hide();
    }

    if (oStyle.image || (!oStyle.range.isCollapsed() || (oStyle.range.sc.tagName && !dom.isAnchor(oStyle.range.sc)) || (oStyle.image && !$(oStyle.image).closest('a').length))) {
        $linkPopover.hide();
        oStyle.anchor = false;
    }

    if (oStyle.image || oStyle.anchor || !$(oStyle.range.sc).closest('.note-editable').length) {
        $airPopover.hide();
    } else {
        $airPopover.show();
    }
};

eventHandler.handle.update = function ($handle, oStyle, isAirMode) {
    $handle.toggle(!!oStyle.image);
    if (oStyle.image) {
        var $selection = $handle.find('.note-control-selection');
        var $image = $(oStyle.image);
        var szImage = {
          w: parseInt($image.outerWidth(true), 10),
          h: parseInt($image.outerHeight(true), 10)
        };
        $selection.data('target', oStyle.image); // save current image element.
        var sSizing = szImage.w + 'x' + szImage.h;
        $selection.find('.note-control-selection-info').text(szImage.h > 50 ? sSizing : "");

        $selection.find('.note-control-sizing').toggleClass('note-control-sizing note-control-holder').css({
                'border-top': 0,
                'border-left': 0
            });
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* hack for image and link editor */

function getImgTarget () {
  return $(".note-control-selection").data('target');
}
eventHandler.editor.padding = function ($editable, sValue) {
    var $target = $(getImgTarget());
    var paddings = "small medium large xl".split(/\s+/);
    $editable.data('NoteHistory').recordUndo();
    if (sValue.length) {
        paddings.splice(paddings.indexOf(sValue),1);
        $target.toggleClass('padding-'+sValue);
    }
    $target.removeClass("padding-" + paddings.join(" padding-"));
};
eventHandler.editor.resize = function ($editable, sValue) {
    var $target = $(getImgTarget());
    $editable.data('NoteHistory').recordUndo();
    var width = ($target.attr('style') || '').match(/(^|;|\s)width:\s*([0-9]+)%/);
    if (width) {
        width = width[2]/100;
    }
    $(getImgTarget()).css('width', width != sValue ? (sValue * 100) + '%' : '');
};
eventHandler.editor.resizefa = function ($editable, sValue) {
    var $target = $(getImgTarget());
    $editable.data('NoteHistory').recordUndo();
    $target.attr('class', $target.attr('class').replace(/\s*fa-[0-9]+x/g, ''));
    if (+sValue > 1) {
        $target.addClass('fa-'+sValue+'x');
    }
};
eventHandler.editor.floatMe = function ($editable, sValue) {
    var $target = $(getImgTarget());
    $editable.data('NoteHistory').recordUndo();
    switch (sValue) {
        case 'center': $target.toggleClass('center-block').removeClass('pull-right pull-left'); break;
        case 'left': $target.toggleClass('pull-left').removeClass('pull-right center-block'); break;
        case 'right': $target.toggleClass('pull-right').removeClass('pull-left center-block'); break;
    }
};
eventHandler.editor.imageShape = function ($editable, sValue) {
    var $target = $(getImgTarget());
    $editable.data('NoteHistory').recordUndo();
    $target.toggleClass(sValue);
};

eventHandler.dialog.showLinkDialog = function ($editable, $dialog, linkInfo) {
    $editable.data('range').select();
    $editable.data('NoteHistory').recordUndo();
    
    var editor = new widgets.LinkDialog($editable, linkInfo);
    editor.appendTo(document.body);

    var def = new $.Deferred();
    editor.on("save", this, function (linkInfo) {
        linkInfo.range.select();
        $editable.data('range', linkInfo.range);
        def.resolve(linkInfo);
        $editable.trigger('keyup');
        $('.note-popover .note-link-popover').show();
    });
    editor.on("cancel", this, function () {
        def.reject();
    });
    return def;
};
eventHandler.dialog.showImageDialog = function ($editable) {
    var r = $editable.data('range');
    if (r.sc.tagName && r.sc.childNodes.length) {
        r.sc = r.sc.childNodes[r.so];
    }
    var editor = new widgets.MediaDialog($editable, dom.isImg(r.sc) ? r.sc : null);
    editor.appendTo(document.body);
    return new $.Deferred().reject();
};
$.summernote.pluginEvents.alt = function (event, editor, layoutInfo, sorted) {
    var $editable = layoutInfo.editable();
    var $selection = layoutInfo.handle().find('.note-control-selection');
    var media = $selection.data('target');
    new widgets.alt($editable, media).appendTo(document.body);
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////

dom.isVoid = function (node) {
    return node && /^BR|^IMG|^HR/.test(node.nodeName.toUpperCase()) || dom.isImg(node);
};
dom.isImg = function (node) {
    return dom.isImgFont(node) || (node && (node.nodeName === "IMG" || (node.className && node.className.match(/(^|\s)media_iframe_video(\s|$)/i)) ));
};
dom.isForbiddenNode = function (node) {
    return $(node).is(".media_iframe_video, .fa, img");
};

dom.isImgFont = function (node) {
    var nodeName = node && node.nodeName.toUpperCase();
    var className = (node && node.className || "");
    if (node && (nodeName === "SPAN" || nodeName === "I") && className.length) {
        var classNames = className.split(/\s+/);
        for (var k=0; k<widgets.fontIcons.length; k++) {
            if (_.intersection(widgets.fontIcons[k].alias, classNames).length) {
                return true;
            }
        }
    }
    return false;
};
// re-overwrite font to include theme icons
var isFont = dom.isFont;
dom.isFont = function (node) {
    return dom.isImgFont(node) || isFont(node);
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////

var fn_visible = $.summernote.pluginEvents.visible;
$.summernote.pluginEvents.visible = function (event, editor, layoutInfo) {
    var res = fn_visible.call(this, event, editor, layoutInfo);
    var $node = $(dom.node(range.create().sc));
    if (($node.is('[data-oe-type="html"]') || $node.is('[data-oe-field="arch"]')) &&
        $node.hasClass("o_editable") &&
        !$node[0].children.length &&
        "h1 h2 h3 h4 h5 h6 p b bold i u code sup strong small pre th td".toUpperCase().indexOf($node[0].nodeName) === -1) {
        var p = $('<p><br/></p>')[0];
        $node.append( p );
        range.createFromNode(p.firstChild).select();
    }
    return res;
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* fix ie and re-range to don't break snippet*/

var initial_data = {};
function reRangeSelectKey (event) {
    initial_data.range = null;
    if (event.shiftKey && event.keyCode >= 37 && event.keyCode <= 40 && !$(event.target).is("input, textarea, select")) {
        var r = range.create();
        if (r) {
            var rng = r.reRange(event.keyCode <= 38);
            if (r !== rng) {
                rng.select();
            }
        }
    }
}
function reRangeSelect (event, dx, dy) {
    var r = range.create();
    if (!r || r.isCollapsed()) return;

    // check if the user move the caret on up or down
    var data = r.reRange(dy < 0 || (dy === 0 && dx < 0));

    if (data.sc !== r.sc || data.so !== r.so || data.ec !== r.ec || data.eo !== r.eo) {
        setTimeout(function () {
            data.select();
            $(data.sc.parentNode).closest('.note-popover');
        },0);
    }

    $(data.sc).closest('.o_editable').data('range', r);
    return r;
}
function summernote_mouseup (event) {
    if ($(event.target).closest("#web_editor-top-navbar, .note-popover").length) {
        return;
    }
    // don't rerange if simple click
    if (initial_data.event) {
        var dx = event.clientX - (event.shiftKey ? initial_data.rect.left : initial_data.event.clientX);
        var dy = event.clientY - (event.shiftKey ? initial_data.rect.top : initial_data.event.clientY);
        if (10 < Math.pow(dx, 2)+Math.pow(dy, 2)) {
            reRangeSelect(event, dx, dy);
        }
    }

    if (!$(event.target).closest(".o_editable").length) {
        return;
    }
    if (!initial_data.range || !event.shiftKey) {
        setTimeout(function () {
            initial_data.range = range.create();
        },0);
    }
}
var remember_selection;
function summernote_mousedown (event) {
    rte.history.splitNext();

    var $editable = $(event.target).closest(".o_editable, .note-editor");
    
    if (!!document.documentMode) {
        summernote_ie_fix(event, function (node) { return node.tagName === "DIV" || node.tagName === "IMG" || (node.dataset && node.dataset.oeModel); });
    } else if (last_div && event.target !== last_div) {
        if (last_div.tagName === "A") {
            summernote_ie_fix(event, function (node) { return node.dataset && node.dataset.oeModel; });
        } else if ($editable.length) {
            if (summernote_ie_fix(event, function (node) { return node.tagName === "A"; })) {
                r = range.create();
                r.select();
            }
        }
    }

    // remember_selection when click on non editable area
    var r = range.create();
    if ($(r ? dom.node(r.sc) : event.srcElement || event.target).closest('#web_editor-top-navbar, #oe_main_menu_navbar, .note-popover, .note-toolbar, .modal').length) {
        if (!$(event.target).is('input, select, label, button, a')) {
            if (!remember_selection && $editable[0]) {
                remember_selection = range.create(dom.firstChild($editable[0]), 0);
            }
            if (!remember_selection && $editable[0]) {
                try {
                    remember_selection.select();
                } catch (e) {
                    console.warn(e);
                }
            }
        }
    } else if (r && $(dom.node(r.sc)).closest('.o_editable, .note-editable').length) {
        remember_selection = r;
    }

    initial_data.event = event;

    // keep selection when click with shift
    if (event.shiftKey && $editable.length) {
        if (initial_data.range) {
            initial_data.range.select();
        }
        var rect = r && r.getClientRects();
        initial_data.rect = rect && rect.length ? rect[0] : { top: 0, left: 0 };
    }
}

var last_div;
var last_div_change;
var last_editable;
function summernote_ie_fix (event, pred) {
    var editable;
    var div;
    var node = event.target;
    while(node.parentNode) {
        if (!div && pred(node)) {
            div = node;
        }
        if(last_div !== node && (node.getAttribute('contentEditable')==='false' || node.className && (node.className.indexOf('o_not_editable') !== -1))) {
            break;
        }
        if (node.className && node.className.indexOf('o_editable') !== -1) {
            if (!div) {
                div = node;
            }
            editable = node;
            break;
        }
        node = node.parentNode;
    }

    if (!editable) {
        $(last_div_change).removeAttr("contentEditable").removeProp("contentEditable");
        $(last_editable).attr("contentEditable", "true").prop("contentEditable", "true");
        last_div_change = null;
        last_editable = null;
        return;
    }

    if (div === last_div) {
        return;
    }

    last_div = div;

    $(last_div_change).removeAttr("contentEditable").removeProp("contentEditable");

    if (last_editable !== editable) {
        if ($(editable).is("[contentEditable='true']")) {
           $(editable).removeAttr("contentEditable").removeProp("contentEditable");
            last_editable = editable;
        } else {
            last_editable = null;
        }
    }
    if (!$(div).attr("contentEditable") && !$(div).is("[data-oe-type='many2one'], [data-oe-type='contact']")) {
        $(div).attr("contentEditable", "true").prop("contentEditable", "true");
        last_div_change = div;
    } else {
        last_div_change = null;
    }
    return editable !== div ? div : null;
}

var fn_attach = eventHandler.attach;
eventHandler.attach = function (oLayoutInfo, options) {
    fn_attach.call(this, oLayoutInfo, options);
    oLayoutInfo.editor.on('dragstart', 'img', function (e) { e.preventDefault(); });
    $(document).on('mousedown', summernote_mousedown);
    $(document).on('mouseup', summernote_mouseup);
    oLayoutInfo.editor.off('click').on('click', function (e) {e.preventDefault();}); // if the content editable is a link
    oLayoutInfo.editor.on('dblclick', 'img, .media_iframe_video, span.fa, i.fa, span.fa', function (event) {
        if (!$(event.target).closest(".note-toolbar").length) { // prevent icon edition of top bar for default summernote
            new widgets.MediaDialog(oLayoutInfo.editor, event.target).appendTo(document.body);
        }
    });
    $(document).on("keyup", reRangeSelectKey);
    
    var clone_data = false;
    var $node = oLayoutInfo.editor;
    if ($node.data('oe-model') || $node.data('oe-translation-id')) {
        $node.on('content_changed', function () {
            var $nodes = $('[data-oe-model], [data-oe-translation-id]')
                .filter(function () { return this != $node[0];});

            if ($node.data('oe-model')) {
                $nodes = $nodes.filter('[data-oe-model="'+$node.data('oe-model')+'"]')
                    .filter('[data-oe-id="'+$node.data('oe-id')+'"]')
                    .filter('[data-oe-field="'+$node.data('oe-field')+'"]');
            }
            if ($node.data('oe-translation-id')) $nodes = $nodes.filter('[data-oe-translation-id="'+$node.data('oe-translation-id')+'"]');
            if ($node.data('oe-type')) $nodes = $nodes.filter('[data-oe-type="'+$node.data('oe-type')+'"]');
            if ($node.data('oe-expression')) $nodes = $nodes.filter('[data-oe-expression="'+$node.data('oe-expression')+'"]');
            if ($node.data('oe-xpath')) $nodes = $nodes.filter('[data-oe-xpath="'+$node.data('oe-xpath')+'"]');
            if ($node.data('oe-contact-options')) $nodes = $nodes.filter('[data-oe-contact-options="'+$node.data('oe-contact-options')+'"]');

            var nodes = $node.get();

            if ($node.data('oe-type') === "many2one") {
                $nodes = $nodes.add($('[data-oe-model]')
                    .filter(function () { return this != $node[0] && nodes.indexOf(this) === -1; })
                    .filter('[data-oe-many2one-model="'+$node.data('oe-many2one-model')+'"]')
                    .filter('[data-oe-many2one-id="'+$node.data('oe-many2one-id')+'"]')
                    .filter('[data-oe-type="many2one"]'));

                $nodes = $nodes.add($('[data-oe-model]')
                    .filter(function () { return this != $node[0] && nodes.indexOf(this) === -1; })
                    .filter('[data-oe-model="'+$node.data('oe-many2one-model')+'"]')
                    .filter('[data-oe-id="'+$node.data('oe-many2one-id')+'"]')
                    .filter('[data-oe-field="name"]'));
            }

            if (!clone_data) {
                clone_data = true;
                $nodes.html(this.innerHTML);
                clone_data = false;
            }
        });
    }

    var $toolbar = $(oLayoutInfo.popover).add(oLayoutInfo.toolbar);
    $('button[data-event="undo"], button[data-event="redo"]', $toolbar).attr('disabled', true);

    $(oLayoutInfo.editor)
        .add(oLayoutInfo.handle)
        .add(oLayoutInfo.popover)
        .add(oLayoutInfo.toolbar)
        .on('click keyup', function () {
            $('button[data-event="undo"]', $toolbar).attr('disabled', !oLayoutInfo.editable.data('NoteHistory').hasUndo());
            $('button[data-event="redo"]', $toolbar).attr('disabled', !oLayoutInfo.editable.data('NoteHistory').hasRedo());
        });
};
var fn_detach = eventHandler.detach;
eventHandler.dettach = function (oLayoutInfo, options) {
    fn_detach.call(this, oLayoutInfo, options);
    oLayoutInfo.editor.off("dragstart");
    $(document).off('mousedown', summernote_mousedown);
    $(document).off('mouseup', summernote_mouseup);
    oLayoutInfo.editor.off("dblclick");
    $(document).off("keyup", reRangeSelectKey);
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Translation for odoo */

$.summernote.lang.odoo = {
    font: {
      bold: _t('Bold'),
      italic: _t('Italic'),
      underline: _t('Underline'),
      strikethrough: _t('Strikethrough'),
      subscript: _t('Subscript'),
      superscript: _t('Superscript'),
      clear: _t('Remove Font Style'),
      height: _t('Line Height'),
      name: _t('Font Family'),
      size: _t('Font Size')
    },
    image: {
      image: _t('Picture'),
      insert: _t('Insert Image'),
      resizeFull: _t('Resize Full'),
      resizeHalf: _t('Resize Half'),
      resizeQuarter: _t('Resize Quarter'),
      floatLeft: _t('Float Left'),
      floatRight: _t('Float Right'),
      floatNone: _t('Float None'),
      dragImageHere: _t('Drag an image here'),
      selectFromFiles: _t('Select from files'),
      url: _t('Image URL'),
      remove: _t('Remove Image')
    },
    link: {
      link: _t('Link'),
      insert: _t('Insert Link'),
      unlink: _t('Unlink'),
      edit: _t('Edit'),
      textToDisplay: _t('Text to display'),
      url: _t('To what URL should this link go?'),
      openInNewWindow: _t('Open in new window')
    },
    video: {
      video: _t('Video'),
      videoLink: _t('Video Link'),
      insert: _t('Insert Video'),
      url: _t('Video URL?'),
      providers: _t('(YouTube, Vimeo, Vine, Instagram, DailyMotion or Youku)')
    },
    table: {
      table: _t('Table')
    },
    hr: {
      insert: _t('Insert Horizontal Rule')
    },
    style: {
      style: _t('Style'),
      normal: _t('Normal'),
      blockquote: _t('Quote'),
      pre: _t('Code'),
      h1: _t('Header 1'),
      h2: _t('Header 2'),
      h3: _t('Header 3'),
      h4: _t('Header 4'),
      h5: _t('Header 5'),
      h6: _t('Header 6')
    },
    lists: {
      unordered: _t('Unordered list'),
      ordered: _t('Ordered list')
    },
    options: {
      help: _t('Help'),
      fullscreen: _t('Full Screen'),
      codeview: _t('Code View')
    },
    paragraph: {
      paragraph: _t('Paragraph'),
      outdent: _t('Outdent'),
      indent: _t('Indent'),
      left: _t('Align left'),
      center: _t('Align center'),
      right: _t('Align right'),
      justify: _t('Justify full')
    },
    color: {
      recent: _t('Recent Color'),
      more: _t('More Color'),
      background: _t('Background Color'),
      foreground: _t('Foreground Color'),
      transparent: _t('Transparent'),
      setTransparent: _t('Set transparent'),
      reset: _t('Reset'),
      resetToDefault: _t('Reset to default')
    },
    shortcut: {
      shortcuts: _t('Keyboard shortcuts'),
      close: _t('Close'),
      textFormatting: _t('Text formatting'),
      action: _t('Action'),
      paragraphFormatting: _t('Paragraph formatting'),
      documentStyle: _t('Document Style')
    },
    history: {
      undo: _t('Undo'),
      redo: _t('Redo')
    }
};

});
