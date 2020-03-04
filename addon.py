import sys
import xbmc
import xbmcgui
import xbmcplugin
import xbmcaddon
import urllib
import urlparse
import os.path
import xml.etree.ElementTree as ET


def get_xml_file_path():
    """ Return (path, filename) """
    # .kodi/userdata/addon_data/[addon name]
    path = xbmc.translatePath(
        addon.getAddonInfo('profile')).decode("utf-8")
    name = addon.getSetting('xml_filename')

    return (path, name)


def copy_default_xml_file(target_file_name):
    try:
        path = addon.getAddonInfo('path').decode('utf-8')
        fin = open(os.path.join(path, "deutschesender.xml"), "r")
        fout = file(target_file_name, "w")
        fout.write(fin.read(-1))  # .encode('utf-8'))
        fout.close()
        fin.close()
    except IOError as e:
        raise e


def make_addon_data_dir():
    import os
    (xml_path, xml_name) = get_xml_file_path()
    try:
        if not os.path.isdir(xml_path):
            os.mkdir(xml_path)
    except OSError:
        addon_name = addon.getAddonInfo("name")
        err = 'Can\'t create folder for addon data.'
        xbmcgui.Dialog().notification(addon_name, err,
                                      xbmcgui.NOTIFICATION_ERROR, 5000)


# For xml update over gui
def update_xml_file():

    import requests

    class FetchError(Exception):
        pass

    # addon = xbmcaddon.Addon()
    addon_name = addon.getAddonInfo("name")
    source_url = addon.getSetting('xml_update_url')
    (xml_path, xml_name) = get_xml_file_path()

    make_addon_data_dir()

    try:
        r = requests.get(source_url)
        if r.status_code != 200:
            raise requests.RequestException(response=r)

        o = file(xml_path+xml_name, "w")
        o.write(r.text.encode(r.encoding))
        # o.write(r.text.encode('utf-8')) # Seems wrong for iso*-input
        o.close()

        info = "File %s updated" % (xml_name,)
        xbmcgui.Dialog().ok(addon_name, info)
    except requests.RequestException as e:
        err = 'Can\'t fetch %s: %s' % (xml_name, e)
        xbmcgui.Dialog().notification(addon_name, err,
                                      xbmcgui.NOTIFICATION_ERROR, 5000)
        # raise FetchError(e)
    except IOError as e:
        err = 'Can\'t create file %s%s: %s' % (xml_path,
                                               xml_name, e)
        xbmcgui.Dialog().notification(addon_name, err,
                                      xbmcgui.NOTIFICATION_ERROR, 5000)
        # raise FetchError(e)


def fetch_channels_from_xml(xml_file, channel_name=None):

    # addon = xbmcaddon.Addon()
    xml_file = "".join(get_xml_file_path())
    if not os.path.isfile(xml_file):
        # 0. Create dir, if ness.
        make_addon_data_dir()

        # 1. Use default file
        copy_default_xml_file(xml_file)

        # 2. Toggle update
        update_xml_file()

    elems = ET.parse(open(xml_file, "r")).getroot()

    if channel_name is None:
        # Return list of channels
        channels = elems.findall("channel")
        ret = []
        for channel in channels:
            ret.append({
                'name': channel.findtext("name"),
                'thumbnail': channel.findtext("thumbnail"),
                'fanart': channel.findtext("fanart"),
            })
        return ret
    else:
        # Return list of items for channel
        ret = []
        channels = elems.findall("channel")
        for channel in channels:
            if channel.findtext("name") == channel_name:
                items = channel.find("items").findall("item")
                for item in items:
                    it = {}
                    for child in item:
                        it[child.tag] = child.text
                    ret.append(it)
                break
        return ret


def build_url(query):
    return base_url + '?' + urllib.urlencode(query)

def resolve_local_paths(path):
    # Translate local paths
    if path and path.startswith("/"):
        path = os.path.join(artfolder, path)

    return path

# Main code

base_url = sys.argv[0]
addon = xbmcaddon.Addon()

# For local images
addonfolder = addon.getAddonInfo('path').decode('utf-8')
artfolder = os.path.join(addonfolder, "resources", "media")


# RunScript handling
if sys.argv[1] == 'update_xml_file':
    update_xml_file()
else:
    addon_handle = int(sys.argv[1])
    args = urlparse.parse_qs(sys.argv[2][1:])

    xbmcplugin.setContent(addon_handle, 'movies')
    # addon = xbmcaddon.Addon()

    # Set default view
    force_view = int(addon.getSetting(u"force_view"))
    if force_view:
        # 50 (List) or 51 (Wide List)
        xbmc.executebuiltin(u"Container.SetViewMode(%i)" %
                            (force_view + 49))

    mode = args.get('mode', None)
    if mode is None:
        channels = fetch_channels_from_xml(addon.getSetting('xml_filename'))
        listing = []
        for channel in channels:
            channel_name = channel.get('name', '?')
            url = build_url({'mode': 'channel', 'channel_name': channel_name})

            fanartImage = channel.get("fanart", "DefaultFolder.png")
            thumbnailImage = channel.get("thumbnail", "DefaultFolder.png")

            fanartImage = resolve_local_paths(fanartImage)
            thumbnailImage = resolve_local_paths(thumbnailImage)

            li = xbmcgui.ListItem(
                channel_name,
                iconImage=fanartImage,
                thumbnailImage=thumbnailImage,
            )

            # Set 'IsPlayable' property to 'true'.
            # This is mandatory for playable items!
            li.setProperty('IsPlayable', 'true')

            # Add the list item to a virtual Kodi folder.
            # is_folder = False means that this item won't open any sub-list.
            is_folder = True

            # Add our item to the listing as a 3-element tuple.
            listing.append((url, li, is_folder))
            # xbmcplugin.addDirectoryItem(handle=addon_handle, url=url,
            #                            listitem=li, isFolder=True)

        xbmcplugin.addDirectoryItems(addon_handle, listing, len(listing))
        xbmcplugin.endOfDirectory(addon_handle)

    elif mode[0] == 'channel':
        channel_name = str(args.get('channel_name')[0])
        items = fetch_channels_from_xml(
            addon.getSetting('xml_filename'), channel_name)
        listing = []
        for item in items:
            title = item.get('title', '?')
            url = item.get('link', '?')
            # if "://" in url: # seems not required
            #    url = urllib.quote(url)
            fanartImage = item.get("fanart", "DefaultFolder.png")
            thumbnailImage = item.get("thumbnail", "DefaultFolder.png")

            fanartImage = resolve_local_paths(fanartImage)
            thumbnailImage = resolve_local_paths(thumbnailImage)

            li = xbmcgui.ListItem(
                title,
                iconImage=fanartImage,
                thumbnailImage=thumbnailImage,
                )
            li.setProperty('IsPlayable', 'true')
            is_folder = False
            listing.append((url, li, is_folder))
            # xbmcplugin.addDirectoryItem(handle=addon_handle,
            #  url=url, listitem=li)

        xbmcplugin.addDirectoryItems(addon_handle, listing, len(listing))
        xbmcplugin.endOfDirectory(addon_handle)
