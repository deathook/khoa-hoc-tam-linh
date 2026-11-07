<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:html="http://www.w3.org/TR/REC-html40"
                xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="vi">
      <head>
        <title>Sơ Đồ Trang Web XML | Khoa Học Tâm Linh</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <style type="text/css">
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            color: #E2E8F0;
            background-color: #0E1117;
            margin: 0;
            padding: 24px;
          }
          .container {
            max-width: 1100px;
            margin: 0 auto;
            background: #181C26;
            border: 1px solid #2B3345;
            border-radius: 16px;
            padding: 28px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
          }
          .header {
            display: flex;
            align-items: center;
            border-bottom: 1px solid #2B3345;
            padding-bottom: 20px;
            margin-bottom: 24px;
          }
          .logo {
            width: 52px;
            height: 52px;
            border-radius: 50%;
            margin-right: 18px;
            border: 2px solid #E5B968;
            box-shadow: 0 0 12px rgba(229, 185, 104, 0.4);
          }
          h1 {
            color: #E5B968;
            font-size: 22px;
            margin: 0 0 6px 0;
            letter-spacing: 0.5px;
          }
          p.desc {
            margin: 0;
            color: #94A3B8;
            font-size: 13.5px;
            line-height: 1.5;
          }
          .stats-bar {
            display: flex;
            gap: 16px;
            margin-bottom: 20px;
            font-size: 13px;
          }
          .badge {
            background: rgba(229, 185, 104, 0.15);
            color: #F3C978;
            padding: 6px 12px;
            border-radius: 20px;
            border: 1px solid rgba(229, 185, 104, 0.3);
            font-weight: 600;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
          }
          th {
            background-color: #222838;
            color: #E5B968;
            text-align: left;
            padding: 12px 14px;
            font-weight: 600;
            border-bottom: 2px solid #2B3345;
          }
          td {
            padding: 10px 14px;
            border-bottom: 1px solid #232A3B;
            word-break: break-all;
          }
          tr:hover td {
            background-color: rgba(229, 185, 104, 0.05);
          }
          a {
            color: #60A5FA;
            text-decoration: none;
            transition: color 0.15s;
          }
          a:hover {
            color: #93C5FD;
            text-decoration: underline;
          }
          .priority {
            font-weight: 600;
            color: #34D399;
          }
          .footer {
            margin-top: 24px;
            padding-top: 16px;
            border-top: 1px solid #2B3345;
            text-align: center;
            font-size: 12px;
            color: #64748B;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <img class="logo" src="/assets/images/app_logo_circle.webp" alt="Khoa Học Tâm Linh Logo" />
            <div>
              <h1>SƠ ĐỒ TRANG WEB XML (XML SITEMAP)</h1>
              <p class="desc">Khoa Học Tâm Linh - Tác giả Hoàng Nhật Minh | The Science of Spirituality</p>
            </div>
          </div>

          <div class="stats-bar">
            <div class="badge">Tổng số liên kết: <xsl:value-of select="count(sitemap:urlset/sitemap:url)"/> URLs</div>
            <div class="badge">Đa ngôn ngữ: Tiếng Việt (VI) &amp; Tiếng Anh (EN)</div>
            <div class="badge">Chuẩn hóa: Google &amp; Bing Sitemap 0.9</div>
          </div>

          <table>
            <thead>
              <tr>
                <th style="width: 50%;">Đường Dẫn URL</th>
                <th style="width: 15%;">Ưu Tiên</th>
                <th style="width: 15%;">Tần Suất</th>
                <th style="width: 20%;">Cập Nhật</th>
              </tr>
            </thead>
            <tbody>
              <xsl:for-each select="sitemap:urlset/sitemap:url">
                <tr>
                  <td>
                    <xsl:variable name="itemURL">
                      <xsl:value-of select="sitemap:loc"/>
                    </xsl:variable>
                    <a href="{$itemURL}" target="_blank">
                      <xsl:value-of select="sitemap:loc"/>
                    </a>
                  </td>
                  <td>
                    <span class="priority">
                      <xsl:value-of select="sitemap:priority"/>
                    </span>
                  </td>
                  <td>
                    <xsl:value-of select="sitemap:changefreq"/>
                  </td>
                  <td style="color: #94A3B8;">
                    <xsl:value-of select="sitemap:lastmod"/>
                  </td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>

          <div class="footer">
            Sơ đồ trang web tạo tự động bởi Khoa Học Tâm Linh © 2026. Hỗ trợ đầy đủ Googlebot, Bingbot, IndexNow.
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
