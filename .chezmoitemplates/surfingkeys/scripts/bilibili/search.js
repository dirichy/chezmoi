skRegisterScript({ name: "bilibili-search", domains: "bilibili.com" }, () => {
  const searchBarSelector = ".center-search__bar";
  const searchFormSelector = "#nav-searchform";
  const searchInputSelector = `${searchFormSelector} .nav-search-input`;
  const searchPanelSelector = ".search-panel";

  const topSearchFromTarget = (target) => {
    if (!(target instanceof Element)) {
      return null;
    }

    const input = target.closest(searchInputSelector);
    if (!input) {
      return null;
    }

    const searchBar = input.closest(searchBarSelector);
    const form = input.closest(searchFormSelector);
    if (!searchBar || !form) {
      return null;
    }

    return {
      form,
      input,
      panel: searchBar.querySelector(searchPanelSelector),
      searchBar,
    };
  };

  const closeTopSearch = ({ form, input, panel, searchBar }) => {
    input.blur();
    form.classList.remove("is-focus");
    searchBar.classList.remove("is-focus");
    form.style.borderRadius = "";

    if (panel) {
      panel.style.display = "none";
    }

    skLog("Bilibili: closed top search panel");
  };

  document.addEventListener(
    "keydown",
    (event) => {
      if (event.key !== "Escape") {
        return;
      }

      const topSearch = topSearchFromTarget(event.target);
      if (!topSearch) {
        return;
      }

      setTimeout(() => closeTopSearch(topSearch), 0);
    },
    true
  );

  document.addEventListener(
    "focusin",
    (event) => {
      const topSearch = topSearchFromTarget(event.target);
      if (!topSearch?.panel) {
        return;
      }

      topSearch.panel.style.display = "";
    },
    true
  );

  skLog("Bilibili: registered top search Escape handler");
});
