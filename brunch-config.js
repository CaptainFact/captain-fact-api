exports.config = {
  files: {
    javascripts: {
      joinTo: {
        "js/ex_admin_common.js": ["web/static/vendor/ex_admin_common.js"],
        "js/admin_lte2.js": ["web/static/vendor/admin_lte2.js"],
        "js/jquery.min.js": ["web/static/vendor/jquery.min.js"],
      }
    },
    stylesheets: {
      joinTo: {
        "css/admin_lte2.css": ["web/static/vendor/admin_lte2.css"],
        "css/active_admin.css.css": ["web/static/vendor/active_admin.css.css"],
      },
      order: {
        after: ["web/static/css/app.css"] // concat app.css last
      }
    }
  },

  conventions: {
    assets: /^(web\/static\/assets)/
  },

  paths: {
    watched: [
      "web/static",
      "test/static"
    ],

    public: "priv/static"
  }
};
