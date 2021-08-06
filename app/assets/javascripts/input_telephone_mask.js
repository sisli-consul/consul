(function() {
  "use strict";
  App.InputTelephoneMask = {
    initialize: function() {
      $("input#residence_phone_number").each(function() {
        $(this).inputmask("(\\9\\0) \\599 999 99 99");
      });
    }
  };
}).call(this);
