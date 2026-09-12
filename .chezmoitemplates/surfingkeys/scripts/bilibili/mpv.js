skRegisterScript({ name: "bilibili-mpv", domains: "bilibili.com" }, ({ script }) => {
  const normalizeVideoUrl = (href) => {
    const url = new URL(href, location.href);
    if (!script.isCurrent(url.hostname) || !/^\/video\/(BV|av)/i.test(url.pathname)) {
      return null;
    }

    const allowedParams = ["p", "t"];
    const paramsToDelete = [];

    url.searchParams.forEach((_, key) => {
      if (!allowedParams.includes(key)) {
        paramsToDelete.push(key);
      }
    });

    paramsToDelete.forEach((key) => url.searchParams.delete(key));

    url.hash = "";
    return url.href;
  };

  const videoPageUrl = (videoUrl) => {
    const url = new URL(videoUrl);
    url.searchParams.set("autoplay", "0");
    return url.href;
  };

  const ensureCurrentVideoPageAutoplayOff = () => {
    const currentVideoUrl = normalizeVideoUrl(location.href);
    if (!currentVideoUrl) {
      return false;
    }

    const pageUrl = videoPageUrl(currentVideoUrl);
    if (location.href === pageUrl) {
      return true;
    }

    skLog("Bilibili: adding autoplay=0 to current video page", pageUrl);
    location.replace(pageUrl);
    return true;
  };

  const watchCurrentVideoPageAutoplayOff = () => {
    let attempts = 0;
    const maxAttempts = 20;

    const timer = setInterval(() => {
      attempts += 1;
      if (ensureCurrentVideoPageAutoplayOff() || attempts >= maxAttempts) {
        clearInterval(timer);
      }
    }, 250);
  };

  const encodeUrl = (url) => {
    const utf8Bytes = new TextEncoder().encode(url);
    let binary = "";
    utf8Bytes.forEach((byte) => {
      binary += String.fromCharCode(byte);
    });

    return btoa(binary).replace(/\//g, "_").replace(/\+/g, "-").replace(/=/g, "");
  };

  const openHandlerWithoutNavigating = (handlerUrl) => {
    const iframe = document.createElement("iframe");
    iframe.style.display = "none";
    iframe.src = handlerUrl;
    document.documentElement.appendChild(iframe);
    setTimeout(() => iframe.remove(), 1000);
  };

  const openInMPV = (videoUrl) => {
    const handlerUrl = `mpv-handler://play/${encodeUrl(videoUrl)}`;
    skLog("Bilibili: opening MPV", { videoUrl, handlerUrl });
    openHandlerWithoutNavigating(handlerUrl);
  };

  const videoUrlFromElementTree = (element) => {
    for (let node = element; node && node !== document.documentElement; node = node.parentElement) {
      const bvid = node.getAttribute("data-bsb-bvid") || node.getAttribute("data-key");
      if (bvid && /^BV[a-zA-Z0-9]+$/.test(bvid)) {
        const videoUrl = normalizeVideoUrl(`/video/${bvid}`);
        if (videoUrl) {
          skLog("Bilibili: video URL found from bvid attribute", {
            bvid,
            videoUrl,
          });
          return videoUrl;
        }
      }

      for (const attribute of node.getAttributeNames()) {
        const value = node.getAttribute(attribute);
        if (!value || !/\/video\/(BV|av)/i.test(value)) {
          continue;
        }

        const videoUrl = normalizeVideoUrl(value);
        if (videoUrl) {
          skLog("Bilibili: video URL found from attribute", {
            attribute,
            value,
            videoUrl,
          });
          return videoUrl;
        }
      }
    }

    return null;
  };

  const collectionItemFromClick = (element) =>
    element.closest(
      ".video-sections-item, .video-pod__item, .action-list-item, .base-video-sections-v1 .video-episode-card, .video-episode-card, .title"
    );

  const videoLinkFromClick = (event) => {
    if (!(event.target instanceof Element)) {
      return null;
    }

    const link = event.target.closest("a[href]");
    if (link) {
      const videoUrl = normalizeVideoUrl(link.href);
      if (videoUrl) {
        return {
          interceptNavigation: true,
          videoUrl,
        };
      }
    }

    const attributedVideoUrl = videoUrlFromElementTree(event.target);
    if (attributedVideoUrl) {
      return {
        interceptNavigation: true,
        videoUrl: attributedVideoUrl,
      };
    }

    if (collectionItemFromClick(event.target)) {
      const currentVideoUrl = normalizeVideoUrl(location.href);
      if (currentVideoUrl) {
        skLog("Bilibili: collection item clicked, using current video URL");
        return {
          interceptNavigation: false,
          videoUrl: currentVideoUrl,
        };
      }
    }

    return null;
  };

  document.addEventListener(
    "click",
    (event) => {
      const action = videoLinkFromClick(event);
      if (!action || event.defaultPrevented) {
        return;
      }

      if (action.interceptNavigation) {
        skStopEvent(event);
      }

      skLog("Bilibili: video link clicked", action);
      openInMPV(action.videoUrl);

      if (action.interceptNavigation) {
        setTimeout(() => {
          const pageUrl = videoPageUrl(action.videoUrl);
          skLog("Bilibili: navigating to video page", pageUrl);
          location.assign(pageUrl);
        }, 100);
      } else {
        watchCurrentVideoPageAutoplayOff();
      }
    },
    true
  );

  if (normalizeVideoUrl(location.href)) {
    skLog("Bilibili: video page detected", normalizeVideoUrl(location.href));
    ensureCurrentVideoPageAutoplayOff();
  }

  skLog("Bilibili: registered video link MPV click handler");
});
