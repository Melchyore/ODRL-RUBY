# frozen_string_literal: true

module ODRL


    # ODRL::Action
    # Describes an action like "use"
    # 
    # @author Mark D Wilkinson
    class Asset < Base
        attr_accessor :uid, :hasPolicy, :refinements, :partOf

        def initialize(args)
            @uid = args[:uid]
            unless @uid
                self.uid = Base.baseURI + "#asset_" + Base.getuuid
            end
            super(args.merge({uid: @uid}))
            self.type="http://www.w3.org/ns/odrl/2/Asset"

            @refinements = Hash.new
            @partOf = args[:partOf]
            @hasPolicy = args[:hasPolicy]

            if @hasPolicy and !(@hasPolicy.is_a? Policy) # if it exists and is the wrong type
                raise "The policy of an Asset must be of type ODRL::Policy.  The provided value will be discarded" 
                @hasPolicy = nil
            end
            if @partOf and !(@partOf.is_a? AssetCollection) # if it exists and is the wrong type
                raise "The parent collection of an Asset must be of type ODRL::AssetCollection.  The provided value will be discarded" 
                @partOf = nil
            end

            args[:refinements] = [args[:refinements]] unless args[:refinements].is_a? Array
            if !(args[:refinements].first.nil?)
                args[:refinements].each do |c|
                    self.addRefinement(refinement:  c)
                end
            end
        end


        def addPart(part: args)
            unless self.is_a?(AssetCollection)
                raise "Asset cannot be added as part of something that is not an asset collection" 
            end
            unless part.is_a?(Asset)
                raise "Only Assets can be added as part of asset collections" 
            end
            part.partOf[self.uid] = [PPARTOF, self] 
        end

        def addRefinement(refinement: args)
            unless refinement.is_a?(Constraint)
                raise "Refinement is not an ODRL Constraint" 
            else
                self.refinements[refinement.uid] = [PREFINEMENT, refinement] 
            end
        end

        def load_graph
            super
            # TODO  This is bad DRY!!  Put the bulk of this method into the base object
            [:refinements, :partOf, :hasPolicy].each do |connected_object_type|
                next unless self.send(connected_object_type)
                self.send(connected_object_type).each do |uid, typedconnection|
                    predicate, odrlobject = typedconnection  # e.g. "refinement", RefinementObject
                    object = odrlobject.uid
                    subject = self.uid
                    repo = self.repository
                    triplify(subject, predicate, object, repo)
                    odrlobject.load_graph  # start the cascade
                end
            end
        end

        def serialize(format:)
            super
        end

    end

    class AssetCollection < Asset

        def initialize(args)
            super(args)
            self.type="http://www.w3.org/ns/odrl/2/AssetCollection"
        end
    end


end
