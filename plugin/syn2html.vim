python <<EOF
colormap = {
   "-1" : "#ffffff",
   "" : "#ffffff",
   "0" : "#000000",
   "1" : "#c00000",
   "2" : "#008000",
   "3" : "#804000",
   "4" : "#0000c0",
   "5" : "#c000c0",
   "6" : "#008080",
   "7" : "#c0c0c0",
   "8" : "#808080",
   "9" : "#ff6060",
   "10" : "#00ff00",
   "11" : "#ffff00",
   "12" : "#8080ff",
   "13" : "#ff40ff",
   "14" : "#00ffff",
   "15" : "#ffffff",
}
if vim.eval('has("gui_running")'):
  use_colormap = 1
else:
  use_colormap = 0

class SyntaxRegion:
  def __init__(self, style, content):
    self.style = style
    self.content = content

  def get_html(self):
    content = self.content.replace('&', '&amp;')
    content = content.replace('<', '&lt;')
    content = content.replace('>', '&gt;')
    content = content.replace('"', '&quot;')
    content = content.replace(' ', '&nbsp;')
    content = content.replace('\n', '<br />\n')
    return '<span class="%s">%s</span>' % (self.style.get_class(), content)

class Style:
  def __init__(self, syn_id):
    self.color = vim.eval('synIDattr(synIDtrans(%s), "fg#")'%syn_id)
    self.name = vim.eval('synIDattr(%s, "name")'%syn_id)
    if use_colormap:
      self.color = colormap[self.color]
      if self.name == '':
        self.name = 'default'
    else:
      if self.color == '':
        self.color = '#ffffff'
        self.name = 'default'
    self.syn_id = syn_id

  def get_style(self):
    return 'span.vim-%s { color:%s }\n' % (self.name,self.color)

  def get_class(self):
    return 'vim-%s' % self.name

  def get_style_id(self):
    return self.syn_id

class StyleSet:
  def __init__(self):
    self.set = []
    self.styles = []

  def add_style(self, style):
    if not style.get_style_id() in self.set:
      self.set.append(style.get_style_id())
      self.styles.append(style)

def createHTML():
  spans = []
  syn_ids = {}
  span = ''
  old_syn_id = -500
  styles = StyleSet()
  for i in range(len(vim.current.buffer)):
    for j in range(len(vim.current.buffer[i])):
      syn_id = vim.eval('synID(%d,%d,1)'%(i+1,j+1))
      if vim.current.buffer[i][j] == ' ':
        span += ' '
        continue
      elif not old_syn_id == -500 and not syn_id == old_syn_id:
        s = Style(old_syn_id)
        styles.add_style(s)
        spans.append(SyntaxRegion(s, span))
        span = ''
      span += vim.current.buffer[i][j]
      old_syn_id = syn_id
    span += '\n'
  spans.append(SyntaxRegion(Style(syn_id), span))

  html = ''
  style_sheet = 'div.code { background-color:white;' \
    'font-family:fixed-width;' \
    'padding:10px;' \
    'margin-top:10px;' \
    'margin-bottom:10px }\n'
  for style in styles.styles:
    style_sheet += style.get_style()
  html += '<style type="text/css">\n%s</style>\n\n'%style_sheet
  html += '<div class="code">'
  for region in spans:
    html += (region.get_html())
  html += '</div>'

  file_name = vim.eval('expand("%")')
  if file_name == '':
    file_name = 'untitled'
  vim.command('new '+file_name+'.html')
  vim.command('set modifiable')
  vim.command('%d')
  for i in html.split('\n'):
    vim.current.buffer.append(i)
  vim.command('1')
  vim.command('d')

EOF
