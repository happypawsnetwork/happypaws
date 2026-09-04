import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/user_profile.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/edit_address_dialog.dart';
import '../widgets/image_cropper_screen.dart';
import 'home_location_map_screen.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final bool openAddressOnMount;

  const EditProfileScreen({super.key, this.openAddressOnMount = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  UserProfile? _initialUser;
  bool _hasAutoOpenedAddress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final profileController = context.read<ProfileController>();
    if (profileController.userProfile == null) {
      await profileController.loadProfile();
    }
    if (mounted) {
      if (profileController.userProfile != null) {
        final user = profileController.userProfile!;
        setState(() {
          _initialUser = user;
        });
      }
      if (widget.openAddressOnMount && !_hasAutoOpenedAddress) {
        _hasAutoOpenedAddress = true;
        _showEditAddressDialog();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        final croppedFile = await ImageCropperScreen.cropImage(
          context,
          File(pickedFile.path),
        );
        if (croppedFile == null || !mounted) return;

        final controller = context.read<EditProfileController>();
        final success = await controller.updateAvatar(croppedFile);
        if (success && mounted) {
          await context.read<ProfileController>().loadProfile(
            forceRefresh: true,
          );
          if (mounted) {
            setState(() {
              _initialUser = context.read<ProfileController>().userProfile;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Avatar updated successfully')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                controller.errorMessage ?? 'Failed to update avatar',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  void _showEditUsernameModal() {
    final controller = context.read<EditProfileController>();
    final user = context.read<ProfileController>().userProfile;
    final textController = TextEditingController(text: user?.username ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditUsernameSheet(
        initialUsername: user?.username ?? '',
        controller: controller,
        textController: textController,
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change profile picture',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Take photo',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleVisibilityToggle(UserRole role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.badge_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                role.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          Switch(
            value: role.isVisible,
            activeThumbColor: AppColors.primary,
            onChanged: (val) async {
              final controller = context.read<EditProfileController>();
              final success = await controller.toggleRoleVisibility(
                role.name,
                val,
              );
              if (success && mounted) {
                await context.read<ProfileController>().loadProfile(
                  forceRefresh: true,
                );
                if (mounted) {
                  setState(() {
                    _initialUser = context
                        .read<ProfileController>()
                        .userProfile;
                  });
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      controller.errorMessage ??
                          'Failed to update role visibility',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveMessagesToggle(bool receiveMessages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Receive Direct Messages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Allow others to message you first',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: receiveMessages,
            activeThumbColor: AppColors.primary,
            onChanged: (val) async {
              final controller = context.read<EditProfileController>();
              final success = await controller.updateReceiveMessages(val);
              if (success && mounted) {
                await context.read<ProfileController>().loadProfile(
                  forceRefresh: true,
                );
                if (mounted) {
                  setState(() {
                    _initialUser = context
                        .read<ProfileController>()
                        .userProfile;
                  });
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      controller.errorMessage ??
                          'Failed to update messaging settings',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_square, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _initialUser?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Name',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty || newName == _initialUser?.name) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                final editController = context.read<EditProfileController>();
                final success = await editController.updateName(newName);
                if (success && mounted) {
                  await context.read<ProfileController>().loadProfile(
                    forceRefresh: true,
                  );
                  if (mounted) {
                    setState(() {
                      _initialUser = context
                          .read<ProfileController>()
                          .userProfile;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated successfully'),
                      ),
                    );
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        editController.errorMessage ?? 'Failed to update name',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaglineDialog() {
    final controller = TextEditingController(text: _initialUser?.tagline ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Tagline',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLength: 150,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Tagline',
              hintText: 'e.g. Dog foster parent in Colombo',
              helperText: 'A short headline visible across Happy Paws',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTagline = controller.text.trim();
                final currentTagline = _initialUser?.tagline?.trim() ?? '';
                if (newTagline == currentTagline) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                final editController = context.read<EditProfileController>();
                final success = await editController.updateTagline(
                  newTagline.isEmpty ? null : newTagline,
                );
                if (success && mounted) {
                  await context.read<ProfileController>().loadProfile(
                    forceRefresh: true,
                  );
                  if (mounted) {
                    setState(() {
                      _initialUser = context
                          .read<ProfileController>()
                          .userProfile;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tagline updated successfully'),
                      ),
                    );
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        editController.errorMessage ??
                            'Failed to update tagline',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditEmailDialog() {
    final controller = TextEditingController(text: _initialUser?.email ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Email',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'New Email Address'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newEmail = controller.text.trim();
                if (newEmail.isEmpty || newEmail == _initialUser?.email) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                _startEmailUpdate(newEmail);
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startEmailUpdate(String newEmail) async {
    final controller = context.read<EditProfileController>();
    final token = await controller.sendEmailUpdateCode(newEmail);
    if (token != null && mounted) {
      _showOtpBottomSheet(token, newEmail);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to send OTP'),
        ),
      );
    }
  }

  void _showOtpBottomSheet(String token, String newEmail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: _OtpEntryWidget(token: token, newEmail: newEmail),
        );
      },
    ).then((success) async {
      if (success == true && mounted) {
        await context.read<ProfileController>().loadProfile(forceRefresh: true);
        if (mounted) {
          setState(() {
            _initialUser = context.read<ProfileController>().userProfile;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email updated successfully')),
          );
        }
      }
    });
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'New password must be at least 6 characters',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final controller = context.read<EditProfileController>();
                final success = await controller.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.errorMessage ?? 'Failed to change password',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAddressDialog() async {
    final currentUser =
        context.read<ProfileController>().userProfile ?? _initialUser;
    final updated = await EditAddressDialog.show(
      context,
      currentUser: currentUser,
    );
    if (updated == true && mounted) {
      setState(() {
        _initialUser = context.read<ProfileController>().userProfile;
      });
    }
  }

  void _showEditLocationMap() async {
    final currentUser =
        context.read<ProfileController>().userProfile ?? _initialUser;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => HomeLocationMapScreen(
          initialPosition:
              currentUser?.homeLatitude != null &&
                  currentUser?.homeLongitude != null
              ? LatLng(currentUser!.homeLatitude!, currentUser.homeLongitude!)
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      final double lat = result['lat'];
      final double lng = result['lng'];

      final controller = context.read<EditProfileController>();
      final latestUser =
          context.read<ProfileController>().userProfile ?? _initialUser;
      final success = await controller.updateLocationAndAddress(
        addressLine1: latestUser?.addressLine1,
        addressLine2: latestUser?.addressLine2,
        city: latestUser?.city,
        state: latestUser?.state,
        postalCode: latestUser?.postalCode,
        country: latestUser?.country,
        homeLatitude: lat,
        homeLongitude: lng,
      );

      if (success && mounted) {
        await context.read<ProfileController>().loadProfile(forceRefresh: true);
        if (mounted) {
          setState(() {
            _initialUser = context.read<ProfileController>().userProfile;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Home location updated successfully')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Failed to update location',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EditProfileController>().isLoading;
    final user = context.watch<ProfileController>().userProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const SizedBox(height: 245, width: double.infinity),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 180,
                        child: const Opacity(
                          opacity: 0.24,
                          child: Image(
                            image: AssetImage(
                              'assets/images/pattern_pet_paws.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 130,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 2.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  backgroundImage:
                                      user?.avatarUrl != null &&
                                          user!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                                  child:
                                      user?.avatarUrl == null ||
                                          user!.avatarUrl!.isEmpty
                                      ? Text(
                                          user?.name.isNotEmpty == true
                                              ? user!.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Semantics(
                                  button: true,
                                  label: 'Change profile picture',
                                  child: GestureDetector(
                                    onTap: _showImageSourcePicker,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (user?.username != null && user!.username!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // The user requested to remove the full name field from the list but also said "Below the Full Name field, there should be the input for setting the username".
                        // Wait, "And the area marked in green should be replaced with the full name (large text), and below that full name, the username should be there... Below the Full Name field, there should be the input for setting the username"
                        // So I will keep Full Name field in the list or did they mean the big text? Let's just keep the field and add Username field below it.
                        _buildFieldRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Full Name',
                          value: user?.name ?? '',
                          onTap: _showEditNameDialog,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Username',
                          value:
                              (user?.username != null &&
                                  user!.username!.isNotEmpty)
                              ? user.username!
                              : 'Not set (choose a unique username)',
                          onTap: _showEditUsernameModal,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          icon: Icons.short_text_rounded,
                          label: 'Tagline',
                          value:
                              (user?.tagline != null &&
                                  user!.tagline!.isNotEmpty)
                              ? user.tagline!
                              : 'Not set (add a short bio headline)',
                          onTap: _showEditTaglineDialog,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: user?.email ?? '',
                          onTap: _showEditEmailDialog,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          icon: Icons.home_outlined,
                          label: 'Home Address',
                          value:
                              (user?.addressLine1 != null &&
                                  user!.addressLine1!.isNotEmpty)
                              ? [user.addressLine1, user.city, user.country]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(', ')
                              : 'Not set (add your home address)',
                          onTap: _showEditAddressDialog,
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildFieldRow(
                          icon: Icons.location_on_outlined,
                          label: 'Accurate Home Location',
                          value:
                              (user?.homeLatitude != null &&
                                  user?.homeLongitude != null)
                              ? '${user!.homeLatitude!.toStringAsFixed(4)}, ${user.homeLongitude!.toStringAsFixed(4)}'
                              : 'Not set (pick from map)',
                          onTap: _showEditLocationMap,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Privacy & Messaging',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildReceiveMessagesToggle(
                          user?.receiveMessages ?? true,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Role Visibility',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (user != null && user.roles.isNotEmpty)
                          ...user.roles.map(
                            (role) => _buildRoleVisibilityToggle(role),
                          ),
                        if (user == null || user.roles.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'No roles assigned yet.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        const Text(
                          'Security',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildFieldRow(
                          icon: Icons.lock_outline_rounded,
                          label: 'Password',
                          value: '••••••••',
                          onTap: _showChangePasswordDialog,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _OtpEntryWidget extends StatefulWidget {
  final String token;
  final String newEmail;
  const _OtpEntryWidget({required this.token, required this.newEmail});

  @override
  State<_OtpEntryWidget> createState() => _OtpEntryWidgetState();
}

class _OtpEntryWidgetState extends State<_OtpEntryWidget> {
  static const int _otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final otp = _otpCode;
    if (otp.length < _otpLength) return;

    final controller = context.read<EditProfileController>();
    final success = await controller.verifyEmailUpdateCode(widget.token, otp);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Verification failed'),
        ),
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      if (digits.length >= _otpLength) {
        _focusNodes[_otpLength - 1].unfocus();
        _handleVerify();
      } else {
        _focusNodes[digits.length.clamp(0, _otpLength - 1)].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_otpCode.length == _otpLength) {
          _handleVerify();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to ',
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            final isFilled = _controllers[index].text.isNotEmpty;

            return SizedBox(
              width: 48,
              height: 56,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      _controllers[index].text.isEmpty &&
                      index > 0) {
                    _focusNodes[index - 1].requestFocus();
                    _controllers[index - 1].clear();
                  }
                },
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isFilled
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: isFilled ? 2 : 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    _onDigitChanged(index, val);
                  },
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _otpCode.length == _otpLength ? _handleVerify : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Verify',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EditUsernameSheet extends StatefulWidget {
  final String initialUsername;
  final EditProfileController controller;
  final TextEditingController textController;

  const _EditUsernameSheet({
    required this.initialUsername,
    required this.controller,
    required this.textController,
  });

  @override
  State<_EditUsernameSheet> createState() => _EditUsernameSheetState();
}

class _EditUsernameSheetState extends State<_EditUsernameSheet> {
  Timer? _debounce;
  bool _isChecking = false;
  bool _isAvailable = true;
  String _currentUsername = "";

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.initialUsername;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    setState(() {
      _currentUsername = value;
      _isChecking = true;
      _isAvailable = false;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.length < 3 || value == widget.initialUsername) {
      setState(() {
        _isChecking = false;
        _isAvailable = value == widget.initialUsername;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await widget.controller.checkUsernameAvailable(value);
      if (mounted) {
        setState(() {
          _isChecking = false;
          _isAvailable = available;
        });
      }
    });
  }

  Future<void> _saveUsername() async {
    if (!_isAvailable || _isChecking) return;
    final success = await widget.controller.updateUsername(_currentUsername);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Set Username",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: widget.textController,
            onChanged: _onUsernameChanged,
            decoration: InputDecoration(
              labelText: "Username",
              prefixText: "@",
              suffixIcon: _currentUsername == widget.initialUsername
                  ? null
                  : _isChecking
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      _isAvailable
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: _isAvailable ? Colors.green : Colors.red,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isAvailable && !_isChecking) ? _saveUsername : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: widget.controller.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Save Username",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}
