from django import template

register = template.Library()


@register.filter(name='getattr')
def getattrfilter(o, attr):
    try:
        return o[attr]
    except:
        return None
