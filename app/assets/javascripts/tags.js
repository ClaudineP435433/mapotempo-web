// Copyright © Mapotempo, 2013-2014
//
// This file is part of Mapotempo.
//
// Mapotempo is free software. You can redistribute it and/or
// modify since you respect the terms of the GNU Affero General
// Public License as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Mapotempo is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Mapotempo. If not, see:
// <http://www.gnu.org/licenses/agpl.html>
//
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var tags_form = function() {
  $('#tag_color').simplecolorpicker({
    theme: 'fontawesome'
  });

  var template = function(state) {
    if (state.id) {
      return $("<img src='/images/" + state.id + ".svg'/>");
    } else {
      return I18n.t('tags.form.icon_default');
    }
  }

  var formatNoMatches = I18n.t('web.select2.empty_result');
  $('#tag_icon').select2({
    theme: 'bootstrap',
    minimumResultsForSearch: -1,
    width: '10em',
    templateResult: template,
    templateSelection: template,
    formatNoMatches: function() {
      return formatNoMatches;
    },
    escapeMarkup: function(m) {
      return m;
    }
  });
}

Paloma.controller('Tag').prototype.new = function() {
  tags_form();
};

Paloma.controller('Tag').prototype.create = function() {
  tags_form();
};

Paloma.controller('Tag').prototype.edit = function() {
  tags_form();
};

Paloma.controller('Tag').prototype.update = function() {
  tags_form();
};

var templateTag = function(item) {
  var color = $(item.element).attr('data-color');
  var icon = $(item.element).attr('data-icon');
  if (icon && color) {
    return $('<span><img src="/images/' + icon + '-' + color + '.svg" />&nbsp;' + item.text + '</span>');
  } else if (icon) {
    return $('<span><img src="/images/' + icon + '.svg" />&nbsp;' + item.text + '</span>');
  } else if (color) {
    return $('<span><i style="color:#' + color + '" class="fa fa-flag" ></i>&nbsp;' + item.text + '</span>');
  } else {
    return item.text;
  }
}
