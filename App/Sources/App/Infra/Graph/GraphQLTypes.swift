import Foundation

typealias Me = PologAPI.MeFragment
extension Me: @unchecked Sendable {}
typealias UserOverview = PologAPI.UserOverviewFragment
extension UserOverview: @unchecked Sendable {}
typealias User = PologAPI.UserFragment
extension User: @unchecked Sendable {}

typealias PologOverview = PologAPI.PologOverviewFragment
extension PologOverview: @unchecked Sendable {}
typealias Polog = PologAPI.PologFragment
extension Polog: @unchecked Sendable {}
typealias PologRoute = PologAPI.PologRouteFragment
extension PologRoute: @unchecked Sendable {}
typealias PologSummary = PologAPI.PologSummaryFragment
extension PologSummary: @unchecked Sendable {}
typealias PologComment = PologAPI.PologCommentFragment
extension PologComment: @unchecked Sendable {}

typealias UserGroupOverview = PologAPI.GroupOverviewFragment
extension UserGroupOverview: @unchecked Sendable {}
typealias UserGroup = PologAPI.GroupFragment
extension UserGroup: @unchecked Sendable {}
typealias SelectGroupMember = PologAPI.SelectGroupMemberFragment
extension SelectGroupMember: @unchecked Sendable {}
typealias GroupAlbumOverview = PologAPI.GroupAlbumOverviewFragment
extension GroupAlbumOverview: @unchecked Sendable {}
typealias GroupAlbum = PologAPI.GroupAlbumFragment
extension GroupAlbum: @unchecked Sendable {}
typealias GroupAsset = PologAPI.GroupAssetFragment
extension GroupAsset: @unchecked Sendable {}

typealias Spot = PologAPI.SpotFragment
extension Spot: @unchecked Sendable {}

typealias Transportation = PologAPI.PologTransportation
extension Transportation: @unchecked Sendable {}
typealias PologVisibility = PologAPI.PologVisibility
extension PologVisibility: @unchecked Sendable {}
typealias AssetKind = PologAPI.AssetKind
extension AssetKind: @unchecked Sendable {}

extension PologAPI.GetMeQuery.Data: @unchecked Sendable {}
extension PologAPI.ExistUserQuery.Data: @unchecked Sendable {}
extension PologAPI.CreateUserMutation.Data: @unchecked Sendable {}
extension PologAPI.GetRecommendedPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetLatestPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetMyFollowingPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.SearchPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.SearchUsersQuery.Data: @unchecked Sendable {}
extension PologAPI.GetFolloweesQuery.Data: @unchecked Sendable {}
extension PologAPI.GetFollowersQuery.Data: @unchecked Sendable {}
extension PologAPI.FollowUserMutation.Data: @unchecked Sendable {}
extension PologAPI.UnFollowUserMutation.Data: @unchecked Sendable {}
extension PologAPI.GetPologSummaryQuery.Data: @unchecked Sendable {}
extension PologAPI.GetMyPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetMyAccompaniedPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetUserQuery.Data: @unchecked Sendable {}
extension PologAPI.GetPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetAccompaniedPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetMyGroupsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetGroupAlbumsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetGroupAssetsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetMutualFollowsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetAllGroupMembersQuery.Data: @unchecked Sendable {}
extension PologAPI.UpdateUserMutation.Data: @unchecked Sendable {}
extension PologAPI.GetMyClippedPologsQuery.Data: @unchecked Sendable {}
extension PologAPI.GetPologQuery.Data: @unchecked Sendable {}
extension PologAPI.LikePologMutation.Data: @unchecked Sendable {}
extension PologAPI.UnLikePologMutation.Data: @unchecked Sendable {}
extension PologAPI.ClipPologMutation.Data: @unchecked Sendable {}
extension PologAPI.UnClipPologMutation.Data: @unchecked Sendable {}
extension PologAPI.DeletePologMutation.Data: @unchecked Sendable {}
extension PologAPI.GetPologCommentsQuery.Data: @unchecked Sendable {}
extension PologAPI.CreatePologCommentMutation.Data: @unchecked Sendable {}
extension PologAPI.GetGroupAssetQuery.Data: @unchecked Sendable {}
extension PologAPI.UpdatePologMutation.Data: @unchecked Sendable {}
extension PologAPI.CreatePologMutation.Data: @unchecked Sendable {}
