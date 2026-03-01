import 'dart:typed_data';

import 'package:bemyday/common/widgets/close_app_bar_button.dart';
import 'package:bemyday/common/widgets/dropdown_button.dart' as common;
import 'package:bemyday/common/widgets/sheet/sheet_item.dart';
import 'package:bemyday/common/widgets/sheet/sheet_select.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/constants/transitions.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:bemyday/features/posting/posting_decorate_screen.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_manager/photo_manager.dart';

class PostingAlbumScreen extends ConsumerStatefulWidget {
  final int? selectedWeekdayIndex;

  const PostingAlbumScreen({super.key, this.selectedWeekdayIndex});
  static const routeName = "postingAlbum";
  static const routeUrl = "/posting/album";

  @override
  ConsumerState<PostingAlbumScreen> createState() => _PostingAlbumScreenState();
}

class _PostingAlbumScreenState extends ConsumerState<PostingAlbumScreen> {
  List<AssetEntity> _assets = [];
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  bool _isLoading = true;
  bool _hasPermission = false;
  final Map<String, Uint8List> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadPhotos();
  }

  Future<void> _requestPermissionAndLoadPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (permission.isAuth) {
      setState(() => _hasPermission = true);
      await _loadAlbums();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isNotEmpty) {
      setState(() {
        _albums = albums;
        _selectedAlbum = albums.first;
      });
      await _loadPhotos();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPhotos() async {
    if (_selectedAlbum == null) return;

    final assets = await _selectedAlbum!.getAssetListRange(start: 0, end: 100);

    setState(() {
      _assets = assets;
      _isLoading = false;
    });
  }

  void _onAlbumChanged(AssetPathEntity? album) {
    if (album == null) return;
    setState(() {
      _selectedAlbum = album;
      _isLoading = true;
    });
    _loadPhotos();
  }

  void _onAssetTap(AssetEntity asset) {
    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];

    if (groups.isEmpty) {
      redirectToInviteIfNoGroups(context, ref);
      return;
    }

    final effectiveIndex = effectivePostingWeekdayIndex(
      groups,
      widget.selectedWeekdayIndex,
    );

    final thumbnail = _thumbnailCache[asset.id];
    Navigator.of(context).push(
      heroPageRoute(
        child: PostingDecorateScreen(
          asset: asset,
          thumbnail: thumbnail,
          selectedWeekdayIndex: effectiveIndex,
        ),
      ),
    );
  }

  void _onCloseTap() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(currentUserGroupsProvider).valueOrNull ?? [];

    if (groups.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        redirectToInviteIfNoGroups(context, ref);
      });
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Select Photo'),
        actions: [CloseAppBarButton(onTap: _onCloseTap)],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_hasPermission
              ? _buildPermissionDenied()
              : _buildContent(),
          if (_albums.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: Sizes.size16),
                    child: _buildAlbumSelector(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumSelector() {
    return common.DropdownButton(
      label: _selectedAlbum?.name ?? 'Album',
      onTap: _showAlbumPicker,
    );
  }

  Future<void> _showAlbumPicker() async {
    // 앨범 카운트를 미리 가져옴
    final albumCounts = await Future.wait(
      _albums.map((album) => album.assetCountAsync),
    );

    if (!mounted) return;

    // 카운트가 1 이상인 앨범만 필터링
    final filteredAlbums = <({AssetPathEntity album, int count})>[];
    for (var i = 0; i < _albums.length; i++) {
      if (albumCounts[i] >= 1) {
        filteredAlbums.add((album: _albums[i], count: albumCounts[i]));
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SheetSelect(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
          items: filteredAlbums.map((item) {
            return SheetItem(
              title: '${item.album.name} (${item.count})',
              onTap: () => _onAlbumChanged(item.album),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.images, size: Sizes.size48),
          SizedBox(height: Sizes.size16),
          Text('Photo access denied'),
          SizedBox(height: Sizes.size8),
          TextButton(
            onPressed: () => PhotoManager.openSetting(),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(Sizes.size2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: ARatio.common,
              crossAxisSpacing: Sizes.size2,
              mainAxisSpacing: Sizes.size2,
            ),
            itemCount: _assets.length,
            itemBuilder: (context, index) {
              final asset = _assets[index];

              return _ThumbnailTile(
                asset: asset,
                thumbnailCache: _thumbnailCache,
                onTap: () => _onAssetTap(asset),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThumbnailTile extends StatefulWidget {
  final AssetEntity asset;
  final Map<String, Uint8List> thumbnailCache;
  final VoidCallback onTap;

  const _ThumbnailTile({
    required this.asset,
    required this.thumbnailCache,
    required this.onTap,
  });

  @override
  State<_ThumbnailTile> createState() => _ThumbnailTileState();
}

class _ThumbnailTileState extends State<_ThumbnailTile> {
  Uint8List? _thumbnail;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    final cached = widget.thumbnailCache[widget.asset.id];
    if (cached != null) {
      _thumbnail = cached;
      _isLoaded = true;
    } else {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
    );

    if (data != null && mounted) {
      widget.thumbnailCache[widget.asset.id] = data;
      setState(() {
        _thumbnail = data;
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _thumbnail == null) {
      return Container(
        color: isDarkMode(context)
            ? CustomColors.clickableAreaDark
            : CustomColors.clickableAreaLight,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: 'photo_${widget.asset.id}',
        child: Image.memory(
          _thumbnail!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
