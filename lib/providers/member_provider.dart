import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/member.dart';
import '../repositories/member_repository.dart';

final Provider<MemberRepository> memberRepositoryProvider =
    Provider<MemberRepository>((Ref ref) {
      return MemberRepository();
    });

final AsyncNotifierProvider<MemberNotifier, List<Member>> memberProvider =
    AsyncNotifierProvider<MemberNotifier, List<Member>>(MemberNotifier.new);

class MemberNotifier extends AsyncNotifier<List<Member>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Member>> build() {
    return ref.read(memberRepositoryProvider).getAll();
  }

  Future<void> addMember(String name) async {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final List<Member> currentMembers = await future;
    final Member member = Member(
      id: _uuid.v4(),
      name: trimmedName,
      sortOrder: currentMembers.length,
    );

    await ref.read(memberRepositoryProvider).save(member);
    state = AsyncData<List<Member>>(<Member>[...currentMembers, member]);
  }

  Future<void> deleteMember(String id) async {
    final List<Member> currentMembers = await future;
    final List<Member> updatedMembers = currentMembers
        .where((Member member) => member.id != id)
        .toList();
    final List<Member> orderedMembers = _withSortOrder(updatedMembers);

    await ref.read(memberRepositoryProvider).delete(id);
    await ref.read(memberRepositoryProvider).saveAll(orderedMembers);
    state = AsyncData<List<Member>>(orderedMembers);
  }

  Future<void> reorderMembers(int oldIndex, int newIndex) async {
    final List<Member> currentMembers = <Member>[...await future];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final Member movedMember = currentMembers.removeAt(oldIndex);
    currentMembers.insert(newIndex, movedMember);
    final List<Member> orderedMembers = _withSortOrder(currentMembers);

    await ref.read(memberRepositoryProvider).saveAll(orderedMembers);
    state = AsyncData<List<Member>>(orderedMembers);
  }

  List<Member> _withSortOrder(List<Member> members) {
    return <Member>[
      for (int index = 0; index < members.length; index++)
        members[index].copyWith(sortOrder: index),
    ];
  }
}
