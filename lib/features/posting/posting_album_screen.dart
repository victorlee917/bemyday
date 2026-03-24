import 'dart:async';
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
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_manager/photo_manager.dart';

class PostingAlbumScreen extends ConsumerStatefulWidget {
  final int? selectedWeekdayIndex;
  final bool replaceOnPostSuccess;

  /// PostScreen에서 주별 목록(`weekIndex` 지정)으로 들어온 경우, 포스팅 후 같은 주로 돌아가기 위해 전달.
  final int? postScreenWeekIndex;

  const PostingAlbumScreen({
    super.key,
    this.selectedWeekdayIndex,
    this.replaceOnPostSuccess = false,
    this.postScreenWeekIndex,
  });
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
  bool _isLoadingAlbumPicker = false;
  bool _hasPermission = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const _pageSize = 100;
  final Map<String, Uint8List> _thumbnailCache = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _requestPermissionAndLoadPhotos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _selectedAlbum == null) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 400) {
      _loadMorePhotos();
    }
  }

  Future<void> _requestPermissionAndLoadPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );

    if (permission.hasAccess) {
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

    setState(() {
      _currentPage = 0;
      _hasMore = true;
    });

    final assets =
        await _selectedAlbum!.getAssetListPaged(page: 0, size: _pageSize);

    if (!mounted) return;
    setState(() {
      _assets = assets;
      _hasMore = assets.length >= _pageSize;
      _isLoading = false;
    });
  }

  Future<void> _loadMorePhotos() async {
    if (_selectedAlbum == null || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final newAssets =
        await _selectedAlbum!.getAssetListPaged(page: nextPage, size: _pageSize);

    if (!mounted) return;
    setState(() {
      _assets = [..._assets, ...newAssets];
      _currentPage = nextPage;
      _hasMore = newAssets.length >= _pageSize;
      _isLoadingMore = false;
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

  void _onAssetTap(AssetEntity asset) async {
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
    await Navigator.of(context).push(
      heroPageRoute(
        child: PostingDecorateScreen(
          asset: asset,
          thumbnail: thumbnail,
          selectedWeekdayIndex: effectiveIndex,
          replaceOnPostSuccess: widget.replaceOnPostSuccess,
          postScreenWeekIndex: widget.postScreenWeekIndex,
        ),
      ),
    );
    // 포스트 성공 시 PostingDecorateScreen에서 posting 전부 pop 후 PostScreen으로 이동
  }

  void _onCloseTap() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.postingSelectPhoto),
        actions: [CloseAppBarButton(onTap: _onCloseTap)],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_hasPermission
              ? _buildPermissionDenied(context)
              : _buildContent(context),
          if (_albums.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: Sizes.size16),
                    child: _buildAlbumSelector(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlbumSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return common.DropdownButton(
      label: _selectedAlbum?.name ?? l10n.postingAlbumFallback,
      onTap: _showAlbumPicker,
      isLoading: _isLoadingAlbumPicker,
      useBlur: true,
    );
  }

  Future<void> _showAlbumPicker() async {
    if (_isLoadingAlbumPicker) return;
    setState(() => _isLoadingAlbumPicker = true);

    try {
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
        builder: (context) {
          return SheetSelect(
            items: filteredAlbums.map((item) {
              return SheetItem(
                title: item.album.name,
                onTap: () => _onAlbumChanged(item.album),
              );
            }).toList(),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isLoadingAlbumPicker = false);
    }
  }

  Widget _buildPermissionDenied(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.images, size: Sizes.size48),
          SizedBox(height: Sizes.size16),
          Text(l10n.postingPhotoAccessDenied),
          SizedBox(height: Sizes.size8),
          TextButton(
            onPressed: () => PhotoManager.openSetting(),
            child: Text(l10n.postingOpenSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_assets.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.images, size: Sizes.size48),
            SizedBox(height: Sizes.size16),
            Text(
              l10n.postingNoPhotosFound,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            cacheExtent: 500,
            padding: EdgeInsets.all(Sizes.size2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: ARatio.common,
              crossAxisSpacing: Sizes.size2,
              mainAxisSpacing: Sizes.size2,
            ),
            itemCount: _assets.length + (_hasMore && _isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _assets.length) {
                return const Padding(
                  padding: EdgeInsets.all(Sizes.size16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
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
  const _ThumbnailTile({
    required this.asset,
    required this.thumbnailCache,
    required this.onTap,
  });

  final AssetEntity asset;
  final Map<String, Uint8List> thumbnailCache;
  final VoidCallback onTap;

  @override
  State<_ThumbnailTile> createState() => _ThumbnailTileState();
}

class _ThumbnailTileState extends State<_ThumbnailTile> {
  Uint8List? _thumbnail;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final cached = widget.thumbnailCache[widget.asset.id];
    if (cached != null) {
      _thumbnail = cached;
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(300, 300),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (data != null && mounted) {
        widget.thumbnailCache[widget.asset.id] = data;
        setState(() {
          _thumbnail = data;
          _loaded = true;
        });
      } else if (mounted) {
        setState(() => _loaded = true);
      }
    } on PlatformException catch (_) {
      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _thumbnail == null) {
      return Container(
        color: isDarkMode(context)
            ? CustomColors.clickableAreaDark
            : CustomColors.clickableAreaLight,
        child: const Center(child: CircularProgressIndicator()),
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
