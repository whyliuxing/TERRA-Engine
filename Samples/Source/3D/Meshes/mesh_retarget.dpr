{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} MaterialDemo;

Uses
{$IFDEF DEBUG_LEAKS}MemCheck,{$ELSE}  TERRA_MemoryManager,{$ENDIF}
  TERRA_DemoApplication, TERRA_Utils, TERRA_Object, TERRA_GraphicsManager,
  TERRA_OS, TERRA_Vector3D, TERRA_Font, TERRA_UI, TERRA_Lights, TERRA_Viewport,
  TERRA_JPG, TERRA_PNG, TERRA_String,
  TERRA_Vector2D, TERRA_Mesh, TERRA_MeshSkeleton, TERRA_MeshAnimation, TERRA_MeshAnimationNodes,
  TERRA_FileManager, TERRA_Color, TERRA_DebugDraw, TERRA_Resource, TERRA_Ray,
  TERRA_ScreenFX, TERRA_Math, TERRA_Matrix3x3, TERRA_Matrix4x4, TERRA_Quaternion, TERRA_InputManager,
  TERRA_FileStream;

Type
  MyDemo = Class(DemoApplication)
    Public

			Procedure OnCreate; Override;
			Procedure OnDestroy; Override;

      Procedure OnRender(V:TERRAViewport); Override;
  End;


Const
  RescaleDuration = 2000;

Var
  ClonedInstance:MeshInstance;
  OriginalInstance:MeshInstance;

  SelectedBone:Integer = 0;


Boo:Boolean;

Type
  AnimationTwister = Class(AnimationProcessor)
    Function PostTransform(State: AnimationState; Bone: AnimationBoneState; Const Block:AnimationTransformBlock): Matrix4x4; Override;
  End;

Function AnimationTwister.PostTransform(State:AnimationState; Bone:AnimationBoneState; Const Block:AnimationTransformBlock):Matrix4x4;
Var
  TargetInstance, SourceInstance:MeshInstance;
  TargetBone, SourceBone:MeshBone;

  Q, QB, QC:Quaternion;
  Angles:Vector3D;
  Pos, SourceAxis, TargetAxis, Direction:Vector3D;
  PX, PY, PZ:Integer;
  M:Matrix4x4;
  T:Single;
Begin
  Result := Matrix4x4Identity;

  If (State = OriginalInstance.Animation) Then
  Begin
    SourceInstance := OriginalInstance;
    TargetInstance := ClonedInstance;
  End Else
  Begin
    SourceInstance := ClonedInstance;
    TargetInstance := OriginalInstance;
  End;

  SourceBone := SourceInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If SourceBone = Nil Then
    Exit;

  TargetBone := TargetInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If TargetBone = Nil Then
    Exit;

  If StringContains('Head', Bone.Name) Then
  Begin
    T := Sin(Application.GetTime() / 1000);
    //Result := Matrix4x4Rotation(0, -90*RAD*T, 0);
    //Result := Matrix4x4Scale(2, 2,2);

    Q := QuaternionMultiply(Bone._BindAbsoluteOrientation, Block.Rotation);
    M := QuaternionMatrix4x4(Q);

    Direction := M.TransformNormal(VectorUp);
    Pos := Bone._FrameAbsoluteMatrix.Transform(VectorZero);
    DrawAxis(MyDemo(Application.Instance).Scene.MainViewport, VectorAdd(SourceInstance.Position, Pos), Direction);
  End;

End;

Type
  AnimationRetargeter = Class(AnimationProcessor)
    //Function PostTransform(State: AnimationState; Bone: AnimationBoneState; Const Block:AnimationTransformBlock): Matrix4x4; Override;
    Function FinalTransform(State: AnimationState; Bone: AnimationBoneState): Matrix4x4; Override;
    Function PreTransform(State: AnimationState; Bone: AnimationBoneState; Const Block:AnimationTransformBlock): Matrix4x4; Override;
  End;

Function AnimationRetargeter.PreTransform(State: AnimationState; Bone: AnimationBoneState; Const Block:AnimationTransformBlock): Matrix4x4;
Var
  SourceBone, TargetBone:MeshBone;
  OtherState:AnimationBoneState;

  T:Vector3D;
  Q:Quaternion;
Begin
  Result := Matrix4x4Identity;

  SourceBone := OriginalInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If SourceBone = Nil Then
    Exit;

  TargetBone := ClonedInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If TargetBone = Nil Then
    Exit;

  // Add the animation state to the rest position
  //Q := QuaternionMultiply(Bone._BindOrientation, Block.Rotation);
  //T := VectorAdd(Bone._BindTranslation, Block.Translation);

  Q := Bone._BindOrientation;
  T := Bone._BindTranslation;
  Result := Matrix4x4Multiply4x3(Matrix4x4Translation(T), QuaternionMatrix4x4(Q));

  If SourceBone.Parent = Nil Then
    Exit;
End;

//Function AnimationRetargeter.PostTransform(State:AnimationState; Bone:AnimationBoneState; Const Block:AnimationTransformBlock):Matrix4x4;
Function AnimationRetargeter.FinalTransform(State:AnimationState; Bone:AnimationBoneState):Matrix4x4;
Var
  SourceBone, TargetBone:MeshBone;
  OtherState:AnimationBoneState;

  A, B, SourceAxis, TargetAxis:Vector3D;
  SourceBoneState:AnimationBoneState;
  SourceLocal, SourceAbs, SourceParentAbs:Matrix4x4;
  S:Single;

  Angles, T:Vector3D;
  Q:Quaternion;
Begin
  Result := Matrix4x4Identity;

  SourceBone := OriginalInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If SourceBone = Nil Then
    Exit;

  TargetBone := ClonedInstance.Geometry.Skeleton.GetBoneByName(Bone.Name);
  If TargetBone = Nil Then
    Exit;

  If SourceBone.Parent = Nil Then
    Exit;

  (*If StringContains('Head', Bone.Name) Then
  Begin
    S := Sin(Application.GetTime() / 1000);
    Result := Matrix4x4Rotation(0, -90*RAD*S, 0);
  End;*)

  //Exit;

  SourceBoneState := OriginalInstance.Animation.GetBoneByName(SourceBone.Name);


  SourceAbs := OriginalInstance.Animation.Transforms[SourceBone.Index + 1];
  SourceParentAbs := OriginalInstance.Animation.Transforms[SourceBone.Parent.Index + 1];

(*  SourceAbs := SourceBoneState._FrameAbsoluteMatrix;
  SourceParentAbs := SourceBoneState._Parent._FrameAbsoluteMatrix;*)

  //Result := Matrix4x4Multiply4x3(Matrix4x4Inverse(SourceParentAbs), SourceAbs);
  Result := SourceAbs;
  //Result.SetTranslation(VectorZero);

  //Result := SourceBoneState._FrameRelativeMatrix;
//  Result.SetTranslation(VectorZero);

//  Result := Matrix4x4Inverse(Result);

  //Result.MoveTransformOrigin(SourceAbs.GetTranslation);
  //Result := Matrix4x4Multiply4x3(SourceAbs, Matrix4x4Inverse(TargetBone.AbsoluteMatrix));
End;


{ MyDemo }
Procedure MyDemo.OnCreate;
Var
  MyMesh, ClonedMesh:TERRAMesh;
  OriginalAnimation, RetargetedAnimation:Animation;
Begin
  Inherited;

  Self.Scene.MainViewport.Camera.SetPosition(VectorCreate(0, 10, 20));
  Self.Scene.MainViewport.Camera.SetView(VectorCreate(0, -0.25, -1));

  MyMesh := MeshManager.Instance.GetMesh('fox');
  If Assigned(MyMesh) Then
  Begin
    OriginalInstance :=MeshInstance.Create(MyMesh);
    OriginalInstance.SetPosition(VectorCreate(5, 0, 0));
    //OriginalInstance.SetRotation(VectorCreate(0, 90*RAD, 0));
  End Else
    OriginalInstance := Nil;

  OriginalAnimation := OriginalInstance.Animation.Find('run');
  OriginalInstance.Animation.Play(OriginalAnimation, RescaleDuration);
  OriginalInstance.Animation.Processor := AnimationTwister.Create();

  //MyMesh := MeshManager.Instance.GetMesh('fox2');
  MyMesh := MeshManager.Instance.GetMesh('monster');
  ClonedMesh := TERRAMesh.Create(rtDynamic, '');
  ClonedMesh.Clone(MyMesh);
  If Assigned(ClonedMesh) Then
  Begin
    ClonedInstance :=MeshInstance.Create(ClonedMesh);
    ClonedInstance.SetPosition(VectorCreate(-5, 0, 0));
  End Else
    ClonedInstance := Nil;


  //ClonedInstance.Geometry.Skeleton.NormalizeJoints();
  //RetargetedAnimation := OriginalAnimation.Retarget(OriginalInstance.Geometry.Skeleton, ClonedInstance.Geometry.Skeleton);
  RetargetedAnimation := Animation.Create(rtDynamic, ''); RetargetedAnimation.Clone(OriginalAnimation);

  ClonedInstance.Animation.Play(RetargetedAnimation, RescaleDuration);
  //ClonedInstance.Animation.Processor := AnimationTwister.Create();
  ClonedInstance.Animation.Processor := AnimationRetargeter.Create();
End;

Procedure MyDemo.OnDestroy;
Begin
  Inherited;
  ReleaseObject(OriginalInstance);
  ReleaseObject(ClonedInstance);
End;

Procedure MyDemo.OnRender(V:TERRAViewport);
Var
  Bone:MeshBone;
Begin
  If V <> Self._Scene.MainViewport Then
    Exit;

  If (InputManager.Instance.Keys.WasPressed(keyU)) And (SelectedBone>0) Then
    Dec(SelectedBone);
  If InputManager.Instance.Keys.WasPressed(keyI) Then
    Inc(SelectedBone);

  //DrawLine2D(V, VectorCreate2D(100, 100), VectorCreate2D(InputManager.Instance.Mouse.X, InputManager.Instance.Mouse.Y), ColorWhite);

  //DrawBoundingBox(V, OriginalInstance.GetBoundingBox, ColorBlue);
  DrawSkeleton(V, OriginalInstance.Geometry.Skeleton,  OriginalInstance.Animation, OriginalInstance.Transform, ColorRed, 4.0);
  DrawSkeleton(V, ClonedInstance.Geometry.Skeleton,  ClonedInstance.Animation, ClonedInstance.Transform, ColorRed, 4.0);

  GraphicsManager.Instance.AddRenderable(V, OriginalInstance);
  GraphicsManager.Instance.AddRenderable(V, ClonedInstance);

  Exit;

(*  AnimationNode(OriginalInstance.Animation.Root).SetCurrentFrame(5);
  AnimationNode(ClonedInstance.Animation.Root).SetCurrentFrame(5);*)

  DrawBone(V, OriginalInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone),  OriginalInstance.Animation, OriginalInstance.Transform, ColorWhite, 4.0);
  DrawBone(V, ClonedInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone),  ClonedInstance.Animation, ClonedInstance.Transform, ColorWhite, 4.0);


  Bone := OriginalInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone);
//  DrawAxis(V, Bone, OriginalInstance.Transform, OriginalInstance.Animation);

  Bone := ClonedInstance.Geometry.Skeleton.GetBoneByIndex(SelectedBone);
  //DrawAxis(V, Bone, ClonedInstance.Transform, ClonedInstance.Animation);

  Self._FontRenderer.SetTransform(MatrixScale2D(2.0));
  Self._FontRenderer.DrawText(50, 250, 10, Bone.Name);
End;

{$IFDEF IPHONE}
Procedure StartGame; cdecl; export;
{$ENDIF}
Begin
  MyDemo.Create();
{$IFDEF IPHONE}
End;
{$ENDIF}
End.

