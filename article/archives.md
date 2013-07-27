template: default
---
# Archives

<ul class="archives">
: for $blog.entries() -> $entry {
<li><time><: $entry.published_at.strftime('%Y-%m-%d') :></time><a href="<: uri_for($entry.site_path()) :>"><: $entry.title :></a></li>
: }
</ul>
